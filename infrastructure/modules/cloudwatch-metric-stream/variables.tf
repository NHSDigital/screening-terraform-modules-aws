################################################################
# Metric stream
################################################################

variable "stream_name" {
  description = "Optional explicit metric-stream name. When null, the name is derived from module.this.id."
  type        = string
  default     = null

  validation {
    condition     = var.stream_name == null || can(regex("^[A-Za-z0-9_-]{1,255}$", var.stream_name))
    error_message = "stream_name must contain only letters, numbers, hyphens, and underscores, with a maximum length of 255 characters."
  }
}

variable "firehose_arn" {
  description = "ARN of the Firehose delivery stream that receives CloudWatch metrics."
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:firehose:", var.firehose_arn))
    error_message = "firehose_arn must be a Firehose delivery stream ARN."
  }
}

variable "role_arn" {
  description = "ARN of the IAM role that allows CloudWatch Metrics to write to Firehose."
  type        = string

  validation {
    condition     = can(regex("^arn:[^:]+:iam::[0-9]{12}:role/.+", var.role_arn))
    error_message = "role_arn must be an IAM role ARN."
  }
}

variable "output_format" {
  description = "Format used by CloudWatch Metric Streams."
  type        = string
  default     = "opentelemetry1.0"

  validation {
    condition     = contains(["json", "opentelemetry0.7", "opentelemetry1.0"], var.output_format)
    error_message = "output_format must be json, opentelemetry0.7, or opentelemetry1.0."
  }
}

variable "include_filter" {
  description = "Metric namespaces and optional names to include. Conflicts with exclude_filter."
  type = list(object({
    namespace    = string
    metric_names = optional(list(string), [])
  }))
  default = []
}

variable "exclude_filter" {
  description = "Metric namespaces and optional names to exclude. Conflicts with include_filter."
  type = list(object({
    namespace    = string
    metric_names = optional(list(string), [])
  }))
  default = []
}

variable "statistics_configuration" {
  description = "Additional statistics and the metrics to stream with those statistics."
  type = list(object({
    additional_statistics = list(string)
    include_metric = list(object({
      metric_name = string
      namespace   = string
    }))
  }))
  default = []
}
