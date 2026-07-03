################################################################
# CloudWatch Metric Alarm submodule inputs.
#
# Naming and tagging come from context.tf via `module.this`.
################################################################

variable "metric_alarm" {
  type = object({
    metric_name         = string
    namespace           = string
    comparison_operator = string
    evaluation_periods  = number
    threshold           = number
    statistic           = optional(string, "Sum")
    period              = optional(number, 60)
    actions_enabled     = optional(bool, true)
  })
  default     = null
  description = "Configuration for a single metric alarm. Set to null to skip creation."

  validation {
    condition = var.metric_alarm == null ? true : contains([
      "SampleCount",
      "Average",
      "Sum",
      "Minimum",
      "Maximum"
    ], var.metric_alarm.statistic)
    error_message = "metric_alarm.statistic must be one of: SampleCount, Average, Sum, Minimum, Maximum."
  }
}

variable "metric_alarms_by_multiple_dimensions" {
  type = object({
    metric_name         = string
    namespace           = string
    comparison_operator = string
    evaluation_periods  = number
    threshold           = number
    statistic           = optional(string, "Sum")
    period              = optional(number, 60)
    actions_enabled     = optional(bool, true)
    dimensions          = map(string)
  })
  default     = null
  description = "Configuration for metric alarms by multiple dimensions (creates one alarm per dimension combo). Set to null to skip creation."

  validation {
    condition = var.metric_alarms_by_multiple_dimensions == null ? true : contains([
      "SampleCount",
      "Average",
      "Sum",
      "Minimum",
      "Maximum"
    ], var.metric_alarms_by_multiple_dimensions.statistic)
    error_message = "metric_alarms_by_multiple_dimensions.statistic must be one of: SampleCount, Average, Sum, Minimum, Maximum."
  }
}

variable "alarm_actions" {
  type        = list(string)
  default     = []
  description = "List of SNS topic ARNs to notify when alarm fires (optional)."
}

variable "ok_actions" {
  type        = list(string)
  default     = []
  description = "List of SNS topic ARNs to notify when alarm recovers (optional)."
}

variable "insufficient_data_actions" {
  type        = list(string)
  default     = []
  description = "List of SNS topic ARNs to notify when alarm has insufficient data (optional)."
}

variable "treat_missing_data" {
  type        = string
  default     = "notBreaching"
  description = "How to handle missing data points: 'notBreaching', 'breaching', 'missing', 'ignoreMetricTime'."

  validation {
    condition     = contains(["notBreaching", "breaching", "missing", "ignoreMetricTime"], var.treat_missing_data)
    error_message = "treat_missing_data must be one of: notBreaching, breaching, missing, ignoreMetricTime."
  }
}
