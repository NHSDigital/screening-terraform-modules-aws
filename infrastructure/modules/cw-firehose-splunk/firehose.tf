##################
#  Common config blocks
##################
# data "terraform_remote_state" "cw_alarm_sns_topic" {
#   backend = "s3"

#   config = {
#     bucket = var.terraform_state_s3_bucket
#     key    = "cw_alarm_sns/terraform.tfstate"
#     region = var.aws_region
#   }
# }

###################
# The Lambda code #
###################
resource "local_file" "preprocess-cw-logs-py" {
  content = templatefile("${path.module}/templates/preprocess-cw-logs.py.tpl", {
    servicePrefix         = var.name_prefix,
    region                = "eu-west-2",
    exclude_extra_logging = var.exclude_extra_logging
  })
  filename = "${path.module}/build/${var.name_prefix}.py"
}

#This causes the local_file.preprocess-cw-logs-py to complete before the archive_file tries to read the .py file
locals {
  depends_on  = [local_file.preprocess-cw-logs-py]
  source_file = local_file.preprocess-cw-logs-py.filename
}

data "archive_file" "preprocess-cw-logs-zip" {
  depends_on  = [local_file.preprocess-cw-logs-py]
  type        = "zip"
  source_file = local.source_file
  output_path = "${path.module}/preprocess-cw-logs-${var.name_prefix}.zip"
}

###############
# Lambda defn #
###############
resource "aws_lambda_function" "preprocess-cw-logs" {
  filename         = data.archive_file.preprocess-cw-logs-zip.output_path
  function_name    = "${var.name_prefix}-preprocess-cw-logs"
  role             = "arn:aws:iam::${var.aws_account_id}:role/${var.name_prefix}_cw_lambda"
  handler          = "${var.name_prefix}.lambda_handler"
  source_code_hash = data.archive_file.preprocess-cw-logs-zip.output_base64sha256
  runtime          = "python3.12"
  timeout          = "180"
}

############
# FIREHOSE #
############

resource "aws_s3_bucket" "undelivered_bucket" {
  bucket = "${var.name_prefix}-cw-fh-dead-letter"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "undelivered_bucket" {
  bucket = aws_s3_bucket.undelivered_bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket                  = aws_s3_bucket.undelivered_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_kinesis_firehose_delivery_stream" "cw_logs_splunk_stream" {
  name        = "${var.name_prefix}-cw-logs-firehose"
  destination = "splunk"

  splunk_configuration {
    hec_endpoint               = var.firehose_splunk_url
    hec_token                  = var.splunk_hec_token
    hec_acknowledgment_timeout = 600
    hec_endpoint_type          = "Raw"
    s3_backup_mode             = "FailedEventsOnly"

    s3_configuration {
      role_arn           = "arn:aws:iam::${var.aws_account_id}:role/${var.name_prefix}_cw_firehose_access_role"
      bucket_arn         = aws_s3_bucket.undelivered_bucket.arn
      buffering_size     = 10
      buffering_interval = 400
      compression_format = "GZIP"
    }

    processing_configuration {
      enabled = "true"

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.preprocess-cw-logs.arn}:$LATEST"
        }
        parameters {
          parameter_name  = "RoleArn"
          parameter_value = aws_iam_role.cw_firehose_iam_role.arn
        }

      }
    }
  }
}

##################
# FIREHOSE Alarm #
##################

# resource "aws_cloudwatch_metric_alarm" "firehose_incoming_bytes_alarm" {
#   depends_on          = [aws_kinesis_firehose_delivery_stream.cw_logs_splunk_stream]
#   alarm_name          = "${var.name_prefix}-firehose-incoming-bytes-alarm"
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = 2
#   metric_name         = "IncomingBytes"
#   namespace           = "AWS/Firehose"
#   period              = 3600
#   statistic           = "Average"
#   threshold           = 800000
#   alarm_description   = "When in alarm, send message to topic ${data.terraform_remote_state.cw_alarm_sns_topic.outputs.cw_alarm_sns_topic_name_home}"
#   dimensions = {
#     FirehoseName = aws_kinesis_firehose_delivery_stream.cw_logs_splunk_stream.name
#   }
#   alarm_actions             = [data.terraform_remote_state.cw_alarm_sns_topic.outputs.cw_alarm_sns_topic_arn_home]
#   ok_actions                = [data.terraform_remote_state.cw_alarm_sns_topic.outputs.cw_alarm_sns_topic_arn_home]
#   insufficient_data_actions = []
#   treat_missing_data        = "notBreaching"

# }
