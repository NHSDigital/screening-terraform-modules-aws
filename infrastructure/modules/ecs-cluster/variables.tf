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
  description = "KMS key ARN or ID for encrypting ECS Exec session data. Required if enable_execute_command is true."
  type        = string
  default     = null
}

variable "cloud_watch_encryption_enabled" {
  description = "Whether to enable encryption for ECS Exec logs stored in CloudWatch Logs. Encryption is mandatory when using CloudWatch destination."
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_name" {
  description = <<-EOT
    Optional name of a pre-created CloudWatch Log Group for ECS Exec session logs.
    The log group must be created separately via the cloudwatch-logs module.
    Either cloudwatch_log_group_name or s3_bucket_name must be provided
    if enable_execute_command is true.
    Example: /bcss/app/prod/ecs/cluster-exec-logs
  EOT
  type        = string
  default     = null
}

################################################################
# ECS Exec S3 logging
################################################################

variable "s3_bucket_name" {
  description = <<-EOT
    Optional S3 bucket name for ECS Exec session logs.
    Either cloudwatch_log_group_name or s3_bucket_name must be provided
    if enable_execute_command is true. If specified, s3_bucket_encryption_enabled
    must be set to true (encryption is mandatory).
    Example: bcss-prod-ecs-exec-logs
  EOT
  type        = string
  default     = null
}

variable "s3_bucket_encryption_enabled" {
  description = <<-EOT
    Whether to enforce encryption on the S3 bucket used for ECS Exec session logs.
    If s3_bucket_name is provided, this must be set to true.
    Encryption is mandatory for ECS Exec session data.
  EOT
  type        = bool
  default     = null
}

variable "s3_kms_key_id" {
  description = <<-EOT
    Optional KMS key ARN or ID to use for encrypting ECS Exec session logs in S3.
    Only relevant if s3_bucket_name is provided and s3_bucket_encryption_enabled is true.
    Example: arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012
  EOT
  type        = string
  default     = null
}

variable "s3_key_prefix" {
  description = <<-EOT
    Optional S3 key prefix for storing ECS Exec session logs.
    All session logs will be stored under this prefix in the S3 bucket.
    If not provided, logs are stored at the bucket root.
    Example: ecs-exec-logs/ or prod/ecs-exec/
  EOT
  type        = string
  default     = null
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
