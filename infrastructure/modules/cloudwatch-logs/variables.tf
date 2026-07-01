################################################################
# CloudWatch Logs submodule inputs.
#
# Naming, tagging and the master `enabled` switch come from
# context.tf via `module.this`.
################################################################

variable "create_log_group" {
  type        = bool
  default     = true
  description = "Whether to create the CloudWatch log group."
}

variable "create_log_stream" {
  type        = bool
  default     = false
  description = "Whether to create a CloudWatch log stream. Requires create_log_group = true."
}

variable "retention_in_days" {
  type        = number
  default     = 7
  description = "CloudWatch log group retention in days. Valid values: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653."

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.retention_in_days)
    error_message = "retention_in_days must be one of: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653."
  }
}

variable "kms_key_id" {
  type        = string
  default     = null
  description = "ARN of KMS key for log group encryption. When null, uses AWS-managed encryption."
}
