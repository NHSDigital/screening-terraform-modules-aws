################################################################
# CloudWatch Metrics to OTLP pipeline
#
# Composes screening wrappers for the metric stream, Firehose,
# OTLP forwarder, S3 failure storage, and least-privilege IAM.
################################################################

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

data "aws_iam_policy_document" "firehose_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "metrics_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["streams.metrics.cloudwatch.amazonaws.com"]
    }
  }
}

locals {
  forwarder_function_name = "${substr(module.this.id, 0, 51)}-otel-metrics"
  forwarder_log_group     = "/aws/lambda/${local.forwarder_function_name}"
  delivery_stream_name    = "${substr(module.this.id, 0, 46)}-otel-metrics"
  metric_stream_name      = "${substr(module.this.id, 0, 180)}-metrics"
  forwarder_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [{
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = ["arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:${local.forwarder_log_group}:*"]
      }],
      length(var.otlp_auth_token_secret_arns) == 0 ? [] : [{
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = distinct(values(var.otlp_auth_token_secret_arns))
      }],
      length(var.secret_kms_key_arns) == 0 ? [] : [{
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = var.secret_kms_key_arns
      }]
    )
  })
  firehose_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:AbortMultipartUpload", "s3:GetBucketLocation", "s3:ListBucket", "s3:ListBucketMultipartUploads"]
        Resource = [module.failure_bucket.bucket_arn]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = ["${module.failure_bucket.bucket_arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction", "lambda:GetFunctionConfiguration"]
        Resource = [module.forwarder.lambda_arn]
      }
    ]
  })
  metrics_stream_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["firehose:PutRecord", "firehose:PutRecordBatch"]
      Resource = ["arn:${data.aws_partition.current.partition}:firehose:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:deliverystream/${local.delivery_stream_name}"]
    }]
  })
}

module "failure_bucket" {
  source = "../s3-bucket"

  context = module.this.context
  name    = "${module.this.name}-otel-metrics-failures"
}

module "iam" {
  source = "../iam"

  context = module.this.context
  name    = "${module.this.name}-otel-metrics-iam"

  roles = {
    firehose = {
      assume_role_policy = data.aws_iam_policy_document.firehose_assume.json
      inline_policies    = { delivery = local.firehose_policy }
    }
    cloudwatch_metrics = {
      assume_role_policy = data.aws_iam_policy_document.metrics_assume.json
      inline_policies    = { delivery = local.metrics_stream_policy }
    }
  }
}

module "forwarder" {
  source = "../lambda"

  context                       = module.this.context
  name                          = "${module.this.name}-otel-metrics-forwarder"
  function_name                 = local.forwarder_function_name
  handler_prefix                = "function"
  function_description          = "Forward CloudWatch Metrics from Firehose to the configured OTLP endpoint"
  python_version                = var.python_version
  source_path                   = "${path.module}/../../lambdas/otel_cw_metrics_python"
  timeout                       = var.lambda_timeout
  attach_default_policies       = false
  attach_cloudwatch_logs_policy = false
  execution_policy_json         = local.forwarder_policy
  environment_variables = {
    OTLP_ENDPOINT                  = var.otlp_endpoint
    OTLP_PROTOCOL                  = var.otlp_protocol
    OTLP_AUTH_TOKEN_SECRET_ARN_MAP = jsonencode(var.otlp_auth_token_secret_arns)
    OTEL_ATTRIBUTE_AUTH_TOKEN_MAP  = jsonencode(var.otel_attribute_auth_token_map)
    OTEL_RESOURCE_ATTRIBUTES       = var.otel_resource_attributes
    METRIC_FORMAT                  = var.metric_format
    KEEP_METRICS_REGEX             = var.keep_metrics_regex
    EXCLUDE_METRICS_REGEX          = var.exclude_metrics_regex
  }
}

module "forwarder_logs" {
  source = "../cloudwatch-logs"

  context        = module.this.context
  name           = "${module.this.name}-otel-metrics-forwarder-log-group"
  log_group_name = local.forwarder_log_group
}

module "firehose" {
  source = "../firehose-extended-s3"

  context              = module.this.context
  name                 = "${module.this.name}-otel-metrics-firehose"
  delivery_stream_name = local.delivery_stream_name
  bucket_arn           = module.failure_bucket.bucket_arn
  role_arn             = module.iam.role_arns["firehose"]
  lambda_arn           = module.forwarder.lambda_arn
  prefix               = var.s3_prefix
}

module "metric_stream" {
  source = "../cloudwatch-metric-stream"

  context     = module.this.context
  name        = "${module.this.name}-otel-metrics-stream"
  stream_name = local.metric_stream_name

  firehose_arn             = module.firehose.delivery_stream_arn
  role_arn                 = module.iam.role_arns["cloudwatch_metrics"]
  output_format            = var.metric_stream_output_format
  include_filter           = var.include_filter
  exclude_filter           = var.exclude_filter
  statistics_configuration = var.statistics_configuration
}
