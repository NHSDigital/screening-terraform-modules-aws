################################################################
# Inspector-specific inputs.
#
# Naming, tagging and the master `enabled` switch come from
# `context.tf` via `module.this` and are forwarded to the
# upstream `cloudposse/inspector/aws` module as `context`.
################################################################

variable "enabled_rules" {
  description = <<-EOT
    A list of AWS Inspector Classic rule packages to run on a periodic basis.
    Valid short identifiers (resolved per-region by the upstream module):
      cve - Common Vulnerabilities & Exposures
      cis - Center for Internet Security benchmarks
      nr  - Network Reachability
      sbp - Security Best Practices
  EOT
  type        = list(string)

  validation {
    condition     = length(var.enabled_rules) > 0
    error_message = "At least one rule package must be specified in enabled_rules."
  }

  validation {
    condition = alltrue([
      for r in var.enabled_rules : contains(["cve", "cis", "nr", "sbp"], r)
    ])
    error_message = "enabled_rules entries must be one of: cve, cis, nr, sbp."
  }
}

variable "assessment_duration" {
  description = "Maximum duration of the Inspector assessment run, in seconds."
  type        = string
  default     = "3600"
}

variable "schedule_expression" {
  description = "AWS CloudWatch schedule expression controlling how often assessments run. See https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html"
  type        = string
  default     = "rate(7 days)"
}

variable "event_rule_description" {
  description = "Description of the CloudWatch event rule that triggers the Inspector assessment."
  type        = string
  default     = "Trigger an AWS Inspector Assessment"
}

################################################################
# IAM role
################################################################

variable "create_iam_role" {
  description = "Whether to create the IAM role used by the CloudWatch event rule to start the Inspector assessment. Set to false to supply an existing role via `iam_role_arn`."
  type        = bool
  default     = false
}

variable "iam_role_arn" {
  description = "ARN of an existing IAM role used to start the Inspector assessment. Only used when `create_iam_role` is false."
  type        = string
  default     = null
}

################################################################
# Notifications
################################################################

variable "assessment_event_subscription" {
  description = <<-EOT
    Map of assessment template event subscriptions. Each entry sends
    notifications about a specified assessment template event to a designated
    SNS topic. Keys are caller-supplied identifiers used as the map key for
    `for_each`-style stability.
  EOT
  type = map(object({
    event     = string
    topic_arn = string
  }))
  default = {}
}
