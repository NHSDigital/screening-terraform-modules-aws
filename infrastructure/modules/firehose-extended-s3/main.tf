################################################################
# Firehose extended S3 delivery stream
#
# First-party primitive for the Firehose behaviour not covered by
# an approved reusable module. Bucket, role, Lambda, and logging
# resources are supplied by the caller.
################################################################

resource "aws_kinesis_firehose_delivery_stream" "this" {
  count = module.this.enabled ? 1 : 0

  name        = coalesce(var.delivery_stream_name, module.this.id)
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = var.role_arn
    bucket_arn          = var.bucket_arn
    prefix              = var.prefix
    error_output_prefix = var.error_output_prefix
    buffering_size      = var.buffering_size_mb
    buffering_interval  = var.buffering_interval_seconds
    compression_format  = var.compression_format

    processing_configuration {
      enabled = true

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = var.lambda_arn
        }

        dynamic "parameters" {
          for_each = var.lambda_buffer_size_mb == 3 ? [] : [var.lambda_buffer_size_mb]

          content {
            parameter_name  = "BufferSizeInMBs"
            parameter_value = tostring(parameters.value)
          }
        }

        dynamic "parameters" {
          for_each = var.lambda_buffer_interval_seconds == 60 ? [] : [var.lambda_buffer_interval_seconds]

          content {
            parameter_name  = "BufferIntervalInSeconds"
            parameter_value = tostring(parameters.value)
          }
        }

        dynamic "parameters" {
          for_each = var.lambda_retries == 3 ? [] : [var.lambda_retries]

          content {
            parameter_name  = "NumberOfRetries"
            parameter_value = tostring(parameters.value)
          }
        }
      }
    }

    dynamic "cloudwatch_logging_options" {
      for_each = var.logging == null || !var.logging.enabled ? [] : [var.logging]

      content {
        enabled         = true
        log_group_name  = cloudwatch_logging_options.value.log_group_name
        log_stream_name = cloudwatch_logging_options.value.log_stream_name
      }
    }
  }

  tags = module.this.tags
}
