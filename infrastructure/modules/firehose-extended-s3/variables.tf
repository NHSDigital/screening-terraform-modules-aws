################################################################
# Delivery destination and processing
################################################################

variable "bucket_arn" {
  description = "ARN of the pre-created private S3 bucket used for Firehose backup and failed records."
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:s3:::[^/]+$", var.bucket_arn))
    error_message = "bucket_arn must be an S3 bucket ARN."
  }
}

variable "delivery_stream_name" {
  description = "Optional explicit delivery stream name. When null, the name is derived from module.this.id."
  type        = string
  default     = null

  validation {
    condition     = var.delivery_stream_name == null || can(regex("^[A-Za-z0-9_-]{1,64}$", var.delivery_stream_name))
    error_message = "delivery_stream_name must contain only letters, numbers, hyphens, and underscores, with a maximum length of 64 characters."
  }
}

variable "role_arn" {
  description = "ARN of the pre-created Firehose delivery role with least-privilege S3, Lambda, and logging permissions."
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:iam::[0-9]{12}:role/.+", var.role_arn))
    error_message = "role_arn must be an IAM role ARN."
  }
}

variable "lambda_arn" {
  description = "ARN of the pre-created Lambda function used to transform Firehose records."
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:lambda:", var.lambda_arn))
    error_message = "lambda_arn must be a Lambda function ARN."
  }
}

variable "prefix" {
  description = "S3 prefix for delivered records. The OTLP forwarders mark successful records Dropped, so this is primarily for retained data."
  type        = string
  default     = "failed-records/"
}

variable "error_output_prefix" {
  description = "S3 prefix for Firehose delivery errors."
  type        = string
  default     = "errors/!{firehose:error-output-type}/"
}

variable "buffering_size_mb" {
  description = "Firehose S3 destination buffer size in MiB."
  type        = number
  default     = 5

  validation {
    condition     = var.buffering_size_mb >= 1 && var.buffering_size_mb <= 128
    error_message = "buffering_size_mb must be between 1 and 128."
  }
}

variable "buffering_interval_seconds" {
  description = "Firehose S3 destination buffering interval in seconds."
  type        = number
  default     = 300

  validation {
    condition     = var.buffering_interval_seconds >= 60 && var.buffering_interval_seconds <= 900
    error_message = "buffering_interval_seconds must be between 60 and 900."
  }
}

variable "compression_format" {
  description = "Compression applied to S3 objects written by Firehose."
  type        = string
  default     = "GZIP"

  validation {
    condition     = contains(["GZIP", "Snappy", "UNCOMPRESSED", "Zip"], var.compression_format)
    error_message = "compression_format must be GZIP, Snappy, UNCOMPRESSED, or Zip."
  }
}

################################################################
# Lambda processor
################################################################

variable "lambda_buffer_size_mb" {
  description = "Buffer size for each Lambda transform invocation in MiB."
  type        = number
  default     = 3

  validation {
    condition     = var.lambda_buffer_size_mb >= 1 && var.lambda_buffer_size_mb <= 6
    error_message = "lambda_buffer_size_mb must be between 1 and 6."
  }
}

variable "lambda_buffer_interval_seconds" {
  description = "Buffer interval for each Lambda transform invocation in seconds."
  type        = number
  default     = 60

  validation {
    condition     = var.lambda_buffer_interval_seconds >= 60 && var.lambda_buffer_interval_seconds <= 900
    error_message = "lambda_buffer_interval_seconds must be between 60 and 900."
  }
}

variable "lambda_retries" {
  description = "Number of Firehose retries when the Lambda transform reports failure."
  type        = number
  default     = 3

  validation {
    condition     = var.lambda_retries >= 0 && var.lambda_retries <= 5
    error_message = "lambda_retries must be between 0 and 5."
  }
}

variable "logging" {
  description = "Optional CloudWatch log group and stream for Firehose delivery logs."
  type = object({
    enabled         = optional(bool, true)
    log_group_name  = string
    log_stream_name = string
  })
  default = null
}
