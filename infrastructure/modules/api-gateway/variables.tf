################################################################
# API configuration
################################################################

variable "custom_name" {
  description = "Optional explicit API name. When null, the name is derived from module.this.id."
  type        = string
  default     = null
}

variable "description" {
  description = "Description for the HTTP API. Keep this focused on the webhook endpoint purpose."
  type        = string
  default     = "HTTP API for a Lambda-backed webhook endpoint."
}

variable "route_key" {
  description = "Route key for the webhook endpoint. Use either '$default' or 'METHOD /path', for example 'POST /webhook'."
  type        = string
  default     = "POST /webhook"

  validation {
    condition     = var.route_key == "$default" || can(regex("^(ANY|DELETE|GET|HEAD|OPTIONS|PATCH|POST|PUT) /.*$", var.route_key))
    error_message = "route_key must be '$default' or in the format 'METHOD /path', for example 'POST /webhook'."
  }
}

variable "stage_name" {
  description = "Stage name for the HTTP API. Defaults to '$default' so callers get auto-deployed changes without managing deployments."
  type        = string
  default     = "$default"

  validation {
    condition     = can(regex("^(\\$default|[A-Za-z0-9_-]{1,128})$", var.stage_name))
    error_message = "stage_name must be '$default' or contain only letters, numbers, underscores, and hyphens."
  }
}

################################################################
# Lambda integration
################################################################

variable "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function that will receive the webhook requests."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:lambda:[^:]+:[0-9]{12}:function:.+", var.lambda_invoke_arn))
    error_message = "lambda_invoke_arn must be a valid Lambda function invoke ARN."
  }
}

variable "lambda_function_name_or_arn" {
  description = "Lambda function name or ARN used when granting API Gateway permission to invoke the function."
  type        = string

  validation {
    condition     = length(trimspace(var.lambda_function_name_or_arn)) > 0
    error_message = "lambda_function_name_or_arn must not be empty."
  }
}

variable "integration_timeout_milliseconds" {
  description = "Timeout for the Lambda proxy integration in milliseconds. HTTP APIs support 50-30000 ms."
  type        = number
  default     = 30000

  validation {
    condition     = var.integration_timeout_milliseconds >= 50 && var.integration_timeout_milliseconds <= 30000
    error_message = "integration_timeout_milliseconds must be between 50 and 30000."
  }
}

################################################################
# Logging and metrics
################################################################

variable "access_log_retention_in_days" {
  description = "CloudWatch Logs retention for API access logs."
  type        = number
  default     = 30

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180,
      365, 400, 545, 731, 1096, 1827, 2192, 2557,
      2922, 3288, 3653
    ], var.access_log_retention_in_days)
    error_message = "access_log_retention_in_days must be a valid CloudWatch Logs retention value."
  }
}

variable "enable_detailed_metrics" {
  description = "Whether to enable detailed CloudWatch metrics on the default route settings."
  type        = bool
  default     = false
}
