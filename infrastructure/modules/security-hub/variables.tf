################################################################
# Security Hub-specific inputs.
#
# Naming, tagging and the master `enabled` switch come from
# `context.tf` via `module.this` — see that file for the full
# list of inherited inputs (service, project, environment,
# stack, name, owner, data_classification, tags, etc.).
################################################################

variable "enable_default_standards" {
  description = "Whether to enable the AWS-recommended default standards (AWS Foundational Security Best Practices and CIS AWS Foundations Benchmark) when Security Hub is first enabled in this account/region."
  type        = bool
  default     = true
}

variable "control_finding_generator" {
  description = "How Security Hub generates findings for security checks. Valid values: SECURITY_CONTROL (consolidated, recommended) or STANDARD_CONTROL (one finding per standard)."
  type        = string
  default     = "SECURITY_CONTROL"

  validation {
    condition     = contains(["SECURITY_CONTROL", "STANDARD_CONTROL"], var.control_finding_generator)
    error_message = "control_finding_generator must be one of SECURITY_CONTROL or STANDARD_CONTROL."
  }
}

variable "auto_enable_controls" {
  description = "Whether new controls added to enabled standards are automatically enabled."
  type        = bool
  default     = true
}

################################################################
# Standards
################################################################

variable "enabled_standards" {
  description = <<-EOT
    A list of Security Hub standards/rulesets to subscribe to. Values can be a
    short identifier (e.g. `standards/aws-foundational-security-best-practices/v/1.0.0`)
    or a full ARN. When a short identifier is supplied, the partition and current
    region are prepended automatically. See:
    https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_standards_subscription
  EOT
  type        = list(string)
  default     = []
}

################################################################
# Finding aggregator
################################################################

variable "finding_aggregator_enabled" {
  description = "Whether to create a Security Hub finding aggregator to consolidate findings across regions."
  type        = bool
  default     = false
}

variable "finding_aggregator_linking_mode" {
  description = "Linking mode for the finding aggregator. One of: ALL_REGIONS, ALL_REGIONS_EXCEPT_SPECIFIED, SPECIFIED_REGIONS."
  type        = string
  default     = "ALL_REGIONS"

  validation {
    condition     = contains(["ALL_REGIONS", "ALL_REGIONS_EXCEPT_SPECIFIED", "SPECIFIED_REGIONS"], var.finding_aggregator_linking_mode)
    error_message = "finding_aggregator_linking_mode must be one of ALL_REGIONS, ALL_REGIONS_EXCEPT_SPECIFIED, SPECIFIED_REGIONS."
  }
}

variable "finding_aggregator_regions" {
  description = "List of regions used by the finding aggregator. Required when `finding_aggregator_linking_mode` is `SPECIFIED_REGIONS` or `ALL_REGIONS_EXCEPT_SPECIFIED`."
  type        = list(string)
  default     = []
}

################################################################
# CloudWatch Event -> SNS forwarding
################################################################

variable "enable_cloudwatch" {
  description = "Create a CloudWatch (EventBridge) rule that forwards Security Hub imported findings. The SNS topic itself is created by the separate alerting module."
  type        = bool
  default     = true
}

variable "cloudwatch_event_rule_pattern_detail_type" {
  description = "The detail-type pattern used to match Security Hub events for the CloudWatch rule."
  type        = string
  default     = "Security Hub Findings - Imported"
}

variable "findings_notification_arn" {
  description = "ARN of an existing SNS topic that Security Hub imported findings should be forwarded to. Leave null to skip target wiring."
  type        = string
  default     = null
}
