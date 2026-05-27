################################################################
# GuardDuty-specific inputs.
#
# Naming, tagging and the master `enabled` switch come from
# `context.tf` via `module.this` — see that file for the full
# list of inherited inputs (service, project, environment,
# stack, name, owner, data_classification, tags, etc.).
################################################################
variable "enable_detector" {
  description = "Enable the GuardDuty detector."
  type        = bool
  default     = false
}

variable "finding_publishing_frequency" {
  description = "Frequency of finding notifications. Valid values: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS. Only meaningful for standalone/master accounts."
  type        = string
  default     = "FIFTEEN_MINUTES"

  validation {
    condition     = var.finding_publishing_frequency == null || contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], coalesce(var.finding_publishing_frequency, "SIX_HOURS"))
    error_message = "finding_publishing_frequency must be one of FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS."
  }
}

################################################################
# Detector feature toggles
################################################################

variable "s3_protection_enabled" {
  description = "Enable S3 Data Events Protection (S3_DATA_EVENTS)."
  type        = bool
  default     = true
}

variable "kubernetes_audit_logs_enabled" {
  description = "Enable EKS audit log monitoring (EKS_AUDIT_LOGS)."
  type        = bool
  default     = false
}

variable "malware_protection_scan_ec2_ebs_volumes_enabled" {
  description = "Enable EBS Malware Protection scanning of EC2 instance volumes (EBS_MALWARE_PROTECTION)."
  type        = bool
  default     = true
}

variable "lambda_network_logs_enabled" {
  description = "Enable Lambda network log monitoring (LAMBDA_NETWORK_LOGS)."
  type        = bool
  default     = false
}

variable "runtime_monitoring_enabled" {
  description = "Enable Runtime Monitoring for EC2, ECS and EKS resources (RUNTIME_MONITORING). Mutually exclusive with eks_runtime_monitoring_enabled."
  type        = bool
  default     = false
}

variable "eks_runtime_monitoring_enabled" {
  description = "Enable standalone EKS Runtime Monitoring (EKS_RUNTIME_MONITORING). Do not enable alongside runtime_monitoring_enabled."
  type        = bool
  default     = false
}

variable "runtime_monitoring_additional_config" {
  description = "Additional configuration for runtime monitoring agent management."
  type = object({
    eks_addon_management_enabled         = optional(bool, false)
    ecs_fargate_agent_management_enabled = optional(bool, false)
    ec2_agent_management_enabled         = optional(bool, false)
  })
  default = {}
}

################################################################
# CloudWatch Event -> SNS forwarding
################################################################

variable "enable_cloudwatch" {
  description = "Create a CloudWatch (EventBridge) rule that forwards GuardDuty findings. The SNS topic itself is created by the separate alerting module."
  type        = bool
  default     = true
}

variable "cloudwatch_event_rule_pattern_detail_type" {
  description = "The detail-type pattern used to match GuardDuty events for the CloudWatch rule."
  type        = string
  default     = "GuardDuty Finding"
}

variable "findings_notification_arn" {
  description = "ARN of an existing SNS topic that GuardDuty findings should be forwarded to. Leave null to skip target wiring."
  type        = string
  default     = null
}
