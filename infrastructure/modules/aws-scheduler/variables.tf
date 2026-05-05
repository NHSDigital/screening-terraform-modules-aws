# ---- Common ----

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

# ---- Lambda Function ----

variable "function_name" {
  description = "Lambda function name"
  type        = string
}

variable "resource_suffix" {
  description = "Sanitized environment name for resource naming"
  type        = string
}

variable "lambda_inputs" {
  description = "Map of key-value pairs to send to the Lambda as input"
  type        = map(string)
  default     = {}
}

variable "start_time" {
  description = "RFC3339 timestamp to use as the scheduler start time"
  type        = string
}

variable "schedule_expression" {
  description = "Schedule expression for the AWS Scheduler (e.g. rate(3 days) or cron(...))"
  type        = string
  default     = null
}
