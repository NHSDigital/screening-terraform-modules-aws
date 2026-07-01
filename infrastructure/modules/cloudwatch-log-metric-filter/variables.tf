################################################################
# CloudWatch Log Metric Filter submodule inputs.
#
# Naming and tagging come from context.tf via `module.this`.
################################################################

variable "log_group_name" {
  type        = string
  description = "Name of the CloudWatch log group to monitor. Required."

  validation {
    condition     = length(var.log_group_name) > 0
    error_message = "log_group_name must not be empty."
  }
}

variable "pattern" {
  type        = string
  default     = ""
  description = "Log pattern to filter on (e.g., 'ERROR', '[ERROR]', etc). Empty string matches all events."
}

variable "metric_transformation_name" {
  type        = string
  description = "Name of the metric to emit (e.g., 'ErrorCount'). Will be prefixed with log group name."

  validation {
    condition     = length(var.metric_transformation_name) > 0
    error_message = "metric_transformation_name must not be empty."
  }
}

variable "metric_transformation_namespace" {
  type        = string
  description = "CloudWatch namespace for the metric (e.g., 'BCSS/Application'). Defaults to log group name if empty."
  default     = ""
}
