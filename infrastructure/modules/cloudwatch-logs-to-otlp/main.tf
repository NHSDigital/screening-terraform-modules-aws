################################################################
# CloudWatch Logs to OTLP pipeline
#
# Composes screening wrappers for the OTLP forwarder, Firehose,
# S3 failure storage, IAM, log subscriptions, and future-group
# enrolment. Existing log groups are discovered at plan time.
################################################################

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

data "aws_cloudwatch_log_groups" "existing" {
  for_each = toset(var.log_group_prefixes)

  log_group_name_prefix = each.value
}

data "aws_iam_policy_document" "firehose_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "logs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
}

locals {
  forwarder_function_name = "${substr(module.this.id, 0, 51)}-otel-logs"
  forwarder_log_group     = "/aws/lambda/${local.forwarder_function_name}"
  delivery_stream_name    = "${substr(module.this.id, 0, 47)}-otel-logs"
  discovered_log_groups   = toset(flatten([for groups in data.aws_cloudwatch_log_groups.existing : groups.log_group_names]))
  group_prefixes = {
    for log_group in local.discovered_log_groups : log_group => one([
      for prefix in var.log_group_prefixes : prefix
      if startswith(log_group, prefix) && length(prefix) == max([
        for candidate in var.log_group_prefixes : length(candidate)
        if startswith(log_group, candidate)
      ]...)
    ])
  }
  existing_log_groups = {
    for log_group, prefix in local.group_prefixes : log_group => lookup(var.prefix_filter_patterns, prefix, var.filter_pattern)
    if !anytrue([for pattern in lookup(var.prefix_exclude_regexes, prefix, []) : can(regex(pattern, log_group))])
  }
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
  logs_delivery_policy = jsonencode({
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
  name    = "${module.this.name}-otel-logs-failures"
}

module "iam" {
  source = "../iam"

  context = module.this.context
  name    = "${module.this.name}-otel-logs-iam"

  roles = {
    firehose = {
      assume_role_policy = data.aws_iam_policy_document.firehose_assume.json
      inline_policies    = { delivery = local.firehose_policy }
    }
    cloudwatch_logs = {
      assume_role_policy = data.aws_iam_policy_document.logs_assume.json
      inline_policies    = { delivery = local.logs_delivery_policy }
    }
  }
}

module "forwarder" {
  source = "../lambda"

  context                       = module.this.context
  name                          = "${module.this.name}-otel-logs-forwarder"
  function_name                 = local.forwarder_function_name
  handler_prefix                = "function"
  function_description          = "Forward CloudWatch Logs from Firehose to the configured OTLP endpoint"
  python_version                = var.python_version
  source_path                   = "${path.module}/../../lambdas/otel_cw_logs_python"
  timeout                       = var.lambda_timeout
  attach_default_policies       = false
  attach_cloudwatch_logs_policy = false
  execution_policy_json         = local.forwarder_policy
  environment_variables = {
    OTLP_ENDPOINT                  = var.otlp_endpoint
    OTLP_PROTOCOL                  = var.otlp_protocol
    OTLP_AUTH_TOKEN_SECRET_ARN_MAP = jsonencode(var.otlp_auth_token_secret_arns)
    LOG_GROUP_AUTH_TOKEN_MAP       = jsonencode(var.log_group_auth_token_map)
    OTEL_ATTRIBUTE_AUTH_TOKEN_MAP  = jsonencode(var.otel_attribute_auth_token_map)
    OTEL_RESOURCE_ATTRIBUTES       = var.otel_resource_attributes
  }
}

module "forwarder_logs" {
  source = "../cloudwatch-logs"

  context        = module.this.context
  name           = "${module.this.name}-otel-logs-forwarder-log-group"
  log_group_name = local.forwarder_log_group
}

module "firehose" {
  source = "../firehose-extended-s3"

  context              = module.this.context
  name                 = "${module.this.name}-otel-logs-firehose"
  delivery_stream_name = local.delivery_stream_name
  bucket_arn           = module.failure_bucket.bucket_arn
  role_arn             = module.iam.role_arns["firehose"]
  lambda_arn           = module.forwarder.lambda_arn
  prefix               = var.s3_prefix
}

module "subscription_dlq" {
  source = "../sqs"

  enabled = module.this.enabled && var.subscribe_future_log_groups
  context = module.this.context
  name    = "${module.this.name}-otel-logs-eventbridge-dlq"

  message_retention_seconds = 1209600
  publisher_statements = {
    eventbridge = {
      principals = {
        type        = "Service"
        identifiers = ["events.amazonaws.com"]
      }
      source_accounts = [data.aws_caller_identity.current.account_id]
    }
  }
}

module "existing_group_subscriptions" {
  source   = "../cloudwatch-log-subscription-filter"
  for_each = local.existing_log_groups

  context = module.this.context
  name    = "${module.this.name}-existing-${substr(sha1(each.key), 0, 12)}"

  log_group_name  = each.key
  destination_arn = module.firehose.delivery_stream_arn
  role_arn        = module.iam.role_arns["cloudwatch_logs"]
  filter_pattern  = each.value
}

module "future_group_subscriptions" {
  count  = module.this.enabled && var.subscribe_future_log_groups ? 1 : 0
  source = "../cloudwatch-log-subscription-controller"

  context = module.this.context
  name    = "${module.this.name}-otel-logs-enrolment"

  log_group_prefixes     = var.log_group_prefixes
  prefix_filter_patterns = var.prefix_filter_patterns
  prefix_exclude_regexes = var.prefix_exclude_regexes
  destination_arn        = module.firehose.delivery_stream_arn
  subscription_role_arn  = module.iam.role_arns["cloudwatch_logs"]
  dead_letter_queue_arn  = module.subscription_dlq.queue_arn
  python_version         = var.python_version
}
