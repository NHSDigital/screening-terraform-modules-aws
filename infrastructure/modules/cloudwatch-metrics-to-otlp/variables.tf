################################################################
# OTLP destination and credentials
################################################################

variable "otlp_endpoint" {
  description = "OTLP collector endpoint, including scheme and port."
  type        = string

  validation {
    condition     = can(regex("^https?://", var.otlp_endpoint))
    error_message = "otlp_endpoint must use HTTP or HTTPS."
  }
}

variable "otlp_protocol" {
  description = "OTLP transport protocol used by the forwarder."
  type        = string
  default     = "grpc"

  validation {
    condition     = contains(["grpc", "http/protobuf"], var.otlp_protocol)
    error_message = "otlp_protocol must be grpc or http/protobuf."
  }
}

variable "otlp_auth_token_secret_arns" {
  description = "Map of token names to Secrets Manager secret ARNs. Values are fetched at Lambda runtime and cached; the default token name is required."
  type        = map(string)

  validation {
    condition = contains(keys(var.otlp_auth_token_secret_arns), "default") && alltrue([
      for arn in values(var.otlp_auth_token_secret_arns) : can(regex("^arn:[^:]+:secretsmanager:[^:]+:[0-9]{12}:secret:.+$", arn))
    ])
    error_message = "otlp_auth_token_secret_arns must contain a default entry and only Secrets Manager ARNs."
  }
}

variable "secret_kms_key_arns" {
  description = "Optional KMS key ARNs used to encrypt the configured Secrets Manager secrets."
  type        = list(string)
  default     = []
}

variable "otel_attribute_auth_token_map" {
  description = "Optional map from resource-attribute selectors to token names."
  type        = map(string)
  default     = {}
}

variable "otel_resource_attributes" {
  description = "Comma-separated OpenTelemetry resource attributes applied to streamed metrics."
  type        = string
  default     = ""
}

################################################################
# Metric selection and conversion
################################################################

variable "include_filter" {
  description = "Optional CloudWatch metric namespaces and names to include. Mutually exclusive with exclude_filter."
  type = list(object({
    namespace    = string
    metric_names = optional(list(string), [])
  }))
  default = []
}

variable "exclude_filter" {
  description = "Optional CloudWatch metric namespaces and names to exclude. Mutually exclusive with include_filter."
  type = list(object({
    namespace    = string
    metric_names = optional(list(string), [])
  }))
  default = []
}

variable "statistics_configuration" {
  description = "Optional additional statistics and metrics to stream."
  type = list(object({
    additional_statistics = list(string)
    include_metric = list(object({
      metric_name = string
      namespace   = string
    }))
  }))
  default = []
}

variable "metric_stream_output_format" {
  description = "Format written by CloudWatch Metric Streams to Firehose."
  type        = string
  default     = "opentelemetry1.0"

  validation {
    condition     = contains(["json", "opentelemetry0.7", "opentelemetry1.0"], var.metric_stream_output_format)
    error_message = "metric_stream_output_format must be json, opentelemetry0.7, or opentelemetry1.0."
  }
}

variable "metric_format" {
  description = "Forwarder output format for metrics."
  type        = string
  default     = "prom"

  validation {
    condition     = contains(["prom", "aws"], var.metric_format)
    error_message = "metric_format must be prom or aws."
  }
}

variable "keep_metrics_regex" {
  description = "Optional regular expression; only final metric names matching it are forwarded."
  type        = string
  default     = ""
}

variable "exclude_metrics_regex" {
  description = "Optional regular expression for final metric names to exclude."
  type        = string
  default     = ""
}

################################################################
# Runtime and delivery
################################################################

variable "python_version" {
  description = "Python runtime used by the metrics forwarder."
  type        = string
  default     = "python3.12"
}

variable "lambda_timeout" {
  description = "Maximum OTLP forwarder execution time in seconds."
  type        = number
  default     = 120

  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "lambda_timeout must be between 1 and 900 seconds."
  }
}

variable "s3_prefix" {
  description = "Prefix for Firehose records retained in the private S3 destination."
  type        = string
  default     = "failed-records/"
}
