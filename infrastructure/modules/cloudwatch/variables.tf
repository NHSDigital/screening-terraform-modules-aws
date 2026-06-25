################################################################
# CloudWatch submodule inputs.
#
# Naming, tagging and the master `enabled` switch come from
# context.tf via `module.this`.
################################################################

variable "log_group" {
  description = "Configuration for the CloudWatch log group submodule. Set to null to skip creating a log group."
  type    = object({})
  default = null
}

variable "log_stream" {
  description = "Configuration for the CloudWatch log stream submodule. Set to null to skip creating a log stream."
  type    = object({})
  default = null
}

variable "log_metric_filter" {
  description = "Configuration for the CloudWatch log metric filter submodule. Set to null to skip creating a log metric filter."
  type = object({
    pattern                             = string
    metric_transformation_name          = string
    metric_transformation_namespace     = string
  })
  default = null
}

variable "metric_alarm" {
  description = "Configuration for the CloudWatch metric alarm submodule. Set to null to skip creating a metric alarm."
  type = object({
    comparison_operator = string
    evaluation_periods  = number
    threshold           = number
  })
  default = null
}

variable "metric_alarms_by_multiple_dimensions" {
  description = "Configuration for the CloudWatch metric alarms by multiple dimensions submodule. Set to null to skip creating these alarms."
  type = object({
    comparison_operator  = string
    evaluation_periods   = number
    threshold            = number
    dimensions           = map(map(string))
  })
  default = null
}
