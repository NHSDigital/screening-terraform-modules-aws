################################################################
# ECS cluster-specific inputs.
#
# Naming, tagging and the master `enabled` switch come from
# context.tf via `module.this`.
################################################################

variable "cluster_name" {
  description = "Optional ECS cluster name. When null, this module uses module.this.id."
  type        = string
  default     = null

  validation {
    condition     = var.cluster_name == null ? true : can(regex("^[A-Za-z0-9_-]{1,255}$", var.cluster_name))
    error_message = "cluster_name must be 1-255 characters and contain only letters, numbers, underscores, and hyphens."
  }
}

variable "enable_container_insights" {
  description = "Whether to enable CloudWatch Container Insights at cluster level."
  type        = bool
  default     = true
}

variable "enable_execute_command" {
  description = "Whether to enable ECS Exec configuration at cluster level."
  type        = bool
  default     = true
}

variable "execute_command_kms_key_id" {
  description = "Optional KMS key ARN or ID for ECS Exec session data encryption."
  type        = string
  default     = null
}

variable "cloudwatch_log_group_name" {
  description = "Optional CloudWatch Log Group name for ECS Exec logs. Defaults to /aws/ecs/<cluster-name>/execute-command."
  type        = string
  default     = null
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "Optional KMS key ARN used to encrypt the CloudWatch Log Group."
  type        = string
  default     = null
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "CloudWatch Log Group retention period in days for ECS Exec logs."
  type        = number
  default     = 90

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.cloudwatch_log_group_retention_in_days)
    error_message = "cloudwatch_log_group_retention_in_days must be a valid CloudWatch retention value."
  }
}

variable "cloudwatch_log_group_class" {
  description = "Optional CloudWatch Log Group class. Valid values are STANDARD or INFREQUENT_ACCESS."
  type        = string
  default     = null

  validation {
    condition     = var.cloudwatch_log_group_class == null ? true : contains(["STANDARD", "INFREQUENT_ACCESS"], var.cloudwatch_log_group_class)
    error_message = "cloudwatch_log_group_class must be STANDARD, INFREQUENT_ACCESS, or null."
  }
}

variable "cluster_capacity_providers" {
  description = "Capacity provider names to associate with the ECS cluster."
  type        = list(string)
  default     = ["FARGATE"]
}

variable "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy definitions keyed by provider name."
  type = map(object({
    base   = optional(number)
    weight = optional(number)
  }))
  default = {
    FARGATE = {
      weight = 100
    }
  }
}

variable "service_connect_defaults" {
  description = "Optional default Service Connect namespace configuration."
  type = object({
    namespace = string
  })
  default = null
}
