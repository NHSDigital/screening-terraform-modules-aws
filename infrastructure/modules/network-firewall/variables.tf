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
# Logging — ALERT (CloudWatch)
################################################################

variable "create_alert_log" {
  description = "Create a CloudWatch Log Group for ALERT logs."
  type        = bool
  default     = true
}

variable "alert_log_retention_in_days" {
  description = "Number of days to retain alert logs in CloudWatch."
  type        = number
  default     = 365
}

variable "alert_log_kms_key_id" {
  description = "ARN of a KMS key to encrypt the CloudWatch alert log group. Leave null for no encryption."
  type        = string
  default     = null
}

################################################################
# Logging — FLOW (S3)
################################################################

variable "flow_log_s3_bucket_name" {
  description = "Name of the S3 bucket for FLOW logs. Leave null to disable S3 flow logging."
  type        = string
  default     = null
}

variable "flow_log_s3_prefix" {
  description = "S3 key prefix for flow logs. Defaults to the module ID."
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
