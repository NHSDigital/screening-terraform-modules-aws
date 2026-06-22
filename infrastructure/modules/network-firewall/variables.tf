################################################################
# Network Firewall-specific inputs.
#
# Naming, tagging and the master `enabled` switch come from
# `context.tf` via `module.this`.
################################################################

################################################################
# VPC / subnets
################################################################

variable "vpc_id" {
  description = "The ID of the VPC where the Network Firewall will be deployed."
  type        = string
}

variable "firewall_subnet_ids" {
  description = "List of firewall subnet IDs (one per AZ) from the VPC module."
  type        = list(string)
}

################################################################
# Firewall settings
################################################################

variable "description" {
  description = "A friendly description of the firewall."
  type        = string
  default     = ""
}

variable "delete_protection" {
  description = "Prevent accidental deletion of the firewall."
  type        = bool
  default     = true
}

variable "subnet_change_protection" {
  description = "Prevent changes to the associated subnets."
  type        = bool
  default     = true
}

variable "firewall_policy_change_protection" {
  description = "Prevent changes to the associated firewall policy."
  type        = bool
  default     = false
}

variable "enabled_analysis_types" {
  description = "Types for which to collect analysis metrics. Valid values: TLS_SNI, HTTP_HOST."
  type        = list(string)
  default     = null
}

################################################################
# Encryption (KMS)
################################################################

variable "kms_key_arn" {
  description = "ARN of a KMS key to encrypt the firewall and its policy. Leave null for AWS-managed encryption."
  type        = string
  default     = null
}

################################################################
# Logging
#
# Flexible logging configuration supporting all combinations of:
#   Log types:    FLOW, ALERT, TLS
#   Destinations: S3, CloudWatchLogs, KinesisDataFirehose
#
# Each entry in the map creates one log_destination_config block
# in the firewall logging configuration. AWS allows at most one
# config per log type (max 3 total).
#
# Destination-specific keys in `log_destination`:
#   S3:                  { bucketName = "...", prefix = "..." }
#   CloudWatchLogs:      { logGroup = "..." }
#   KinesisDataFirehose: { deliveryStream = "..." }
#
# If `enabled` is omitted it defaults to true. Use `enabled = false`
# to temporarily disable a destination without removing it.
#
# Example:
#   logging = {
#     flow_s3 = {
#       log_type             = "FLOW"
#       log_destination_type = "S3"
#       log_destination      = { bucketName = "my-bucket", prefix = "nwfw" }
#     }
#     alert_cloudwatch = {
#       log_type             = "ALERT"
#       log_destination_type = "CloudWatchLogs"
#       log_destination      = { logGroup = "/aws/network-firewall/alerts" }
#     }
#   }
#
# TODO(logging): Add support for managed CloudWatch log group per
#   log type (similar to create_alert_log_group) so callers don't
#   need to create log groups externally when using CloudWatchLogs.
# TODO(logging): Add support for managed Kinesis Firehose delivery
#   stream if demand arises from consuming teams.
################################################################

variable "logging" {
  description = "Map of logging destinations. Each key creates one log_destination_config block. See variable comments for shape and examples."
  type = map(object({
    enabled              = optional(bool, true)
    log_type             = string      # FLOW, ALERT, or TLS
    log_destination_type = string      # S3, CloudWatchLogs, or KinesisDataFirehose
    log_destination      = map(string) # destination-specific keys (see comments above)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.logging : contains(["FLOW", "ALERT", "TLS"], v.log_type)
    ])
    error_message = "Each logging entry's log_type must be one of: FLOW, ALERT, TLS."
  }

  validation {
    condition = alltrue([
      for k, v in var.logging : contains(["S3", "CloudWatchLogs", "KinesisDataFirehose"], v.log_destination_type)
    ])
    error_message = "Each logging entry's log_destination_type must be one of: S3, CloudWatchLogs, KinesisDataFirehose."
  }
}

variable "create_logging_configuration" {
  description = "Master toggle for logging configuration. Must be plan-time-known. When true, the `logging` map is used to build destination configs."
  type        = bool
  default     = false
}

################################################################
# Managed CloudWatch Log Group
#
# Convenience resource for callers who want this module to own
# the CloudWatch log group lifecycle (retention, KMS encryption)
# rather than creating it externally.
#
# When enabled, the log group name is automatically set to
# `/aws/network-firewall/<module.this.id>` and can be referenced
# in the `logging` map via:
#   log_destination = { logGroup = module.nwfw.alert_log_group_name }
################################################################

variable "create_alert_log_group" {
  description = "Create a managed CloudWatch Log Group for ALERT logs. The log group name is exposed via the alert_log_group_name output."
  type        = bool
  default     = false
}

variable "alert_log_group_retention_in_days" {
  description = "Number of days to retain logs in the managed alert log group."
  type        = number
  default     = 365
}

variable "alert_log_group_kms_key_id" {
  description = "ARN of a KMS key to encrypt the managed CloudWatch alert log group. Leave null for no encryption."
  type        = string
  default     = null
}

################################################################
# Firewall policy
################################################################

variable "create_policy" {
  description = "Create the firewall policy. Set to false and supply firewall_policy_arn to use an externally managed policy."
  type        = bool
  default     = true
}

variable "firewall_policy_arn" {
  description = "ARN of an externally managed firewall policy. Only used when create_policy is false."
  type        = string
  default     = ""
}

variable "policy_stateless_default_actions" {
  description = "Actions for packets that match no stateless rules. Default forwards all traffic to the stateful engine."
  type        = list(string)
  default     = ["aws:forward_to_sfe"]
}

variable "policy_stateless_fragment_default_actions" {
  description = "Actions for fragmented packets that match no stateless rules."
  type        = list(string)
  default     = ["aws:forward_to_sfe"]
}

variable "policy_stateful_default_actions" {
  description = "Actions for packets that match no stateful rules. Only valid with STRICT_ORDER rule order."
  type        = list(string)
  default     = null
}

variable "policy_stateful_engine_options" {
  description = "Stateful engine options (rule_order, stream_exception_policy, flow_timeouts)."
  type = object({
    flow_timeouts = optional(object({
      tcp_idle_timeout_seconds = optional(number)
    }))
    rule_order              = optional(string)
    stream_exception_policy = optional(string)
  })
  default = null
}

variable "policy_stateful_rule_group_reference" {
  description = "Map of stateful rule group references for the policy."
  type = map(object({
    deep_threat_inspection = optional(bool)
    override = optional(object({
      action = optional(string)
    }))
    priority     = optional(number)
    resource_arn = string
  }))
  default = null
}

variable "policy_stateless_rule_group_reference" {
  description = "Map of stateless rule group references for the policy."
  type = map(object({
    priority     = number
    resource_arn = string
  }))
  default = null
}

variable "policy_stateless_custom_action" {
  description = "Custom action definitions for the firewall policy's stateless default actions."
  type = map(object({
    action_definition = object({
      publish_metric_action = optional(object({
        dimension = optional(string)
      }))
    })
    action_name = string
  }))
  default = null
}

variable "policy_variables" {
  description = "Variables to override default Suricata settings in the firewall policy."
  type = object({
    rule_variables = list(object({
      ip_set = optional(object({
        definition = list(string)
      }))
      key = string
    }))
  })
  default = null
}

################################################################
# Rule groups
#
# Map of rule group definitions created alongside the firewall.
# Each entry creates a rule group via the upstream rule-group
# submodule and automatically wires it into the firewall policy.
#
# For Suricata-format rules (most common), use `rules` with a
# heredoc string. For structured rules, use `rule_group`.
#
# Example:
#   rule_groups = {
#     block_legacy_tls = {
#       description = "Reject TLS 1.0/1.1"
#       type        = "STATEFUL"
#       capacity    = 10
#       priority    = 100
#       rules       = "reject tls any any -> any any (msg:\"Block TLS 1.0/1.1\"; ssl_version:tls1.0,tls1.1; sid:100001;)"
#       rule_group = {
#         stateful_rule_options = { rule_order = "STRICT_ORDER" }
#       }
#     }
#     deny_domains = {
#       description = "Block known-bad domains"
#       type        = "STATEFUL"
#       capacity    = 100
#       priority    = 500
#       rule_group = {
#         stateful_rule_options = { rule_order = "STRICT_ORDER" }
#         rules_source = {
#           rules_source_list = {
#             generated_rules_type = "DENYLIST"
#             target_types         = ["TLS_SNI", "HTTP_HOST"]
#             targets              = ["evil.com", ".malware.net"]
#           }
#         }
#       }
#     }
#   }
################################################################

variable "rule_groups" {
  description = "Map of rule group definitions to create and attach to the firewall policy. See variable comments for shape and examples."
  type = map(object({
    description = optional(string)
    type        = optional(string, "STATEFUL")
    capacity    = optional(number, 100)
    priority    = optional(number)
    rules       = optional(string)
    rule_group  = optional(any)
  }))
  default = {}
}
