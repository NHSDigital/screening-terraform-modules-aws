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

variable "log_group_auth_token_map" {
  description = "Optional map from log-group selector patterns to token names."
  type        = map(string)
  default     = {}
}

variable "otel_attribute_auth_token_map" {
  description = "Optional map from resource-attribute selectors to token names."
  type        = map(string)
  default     = {}
}

variable "otel_resource_attributes" {
  description = "Comma-separated OpenTelemetry resource attributes applied to forwarded log records."
  type        = string
  default     = ""
}

################################################################
# Log selection and subscription
################################################################

variable "log_group_prefixes" {
  description = "Non-empty list of log-group prefixes to subscribe, both for discovered existing groups and future groups."
  type        = list(string)

  validation {
    condition     = length(var.log_group_prefixes) > 0 && alltrue([for prefix in var.log_group_prefixes : length(trimspace(prefix)) > 0])
    error_message = "log_group_prefixes must contain at least one non-empty prefix."
  }
}

variable "prefix_filter_patterns" {
  description = "Optional CloudWatch Logs filter patterns keyed by prefix; the longest matching prefix wins."
  type        = map(string)
  default     = {}
}

variable "prefix_exclude_regexes" {
  description = "Optional regular expressions keyed by prefix to exclude matching log-group names."
  type        = map(list(string))
  default     = {}

  validation {
    condition = alltrue(flatten([
      for patterns in values(var.prefix_exclude_regexes) : [
        for pattern in patterns : can(regexall(pattern, ""))
      ]
    ]))
    error_message = "Each prefix exclusion must be a valid regular expression."
  }
}

variable "filter_pattern" {
  description = "Default CloudWatch Logs filter pattern for prefixes without an explicit pattern."
  type        = string
  default     = ""
}

variable "subscribe_future_log_groups" {
  description = "Whether to enrol future matching log groups through CloudTrail and EventBridge."
  type        = bool
  default     = true
}

################################################################
# Runtime and delivery
################################################################

variable "python_version" {
  description = "Python runtime used by the forwarder and subscription controller."
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
