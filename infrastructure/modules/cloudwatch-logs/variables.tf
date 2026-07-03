################################################################
# CloudWatch Logs submodule inputs.
#
# Naming, tagging and the master `enabled` switch come from
# context.tf via `module.this`.
################################################################

variable "create" {
  type        = string
  default     = "LOG_GROUP_ONLY"
  description = "Creation mode for CloudWatch log resources. Valid values are NOTHING, LOG_GROUP_ONLY, and LOG_GROUP_AND_LOG_STREAM."

  validation {
    condition     = contains(["NOTHING", "LOG_GROUP_ONLY", "LOG_GROUP_AND_LOG_STREAM"], var.create)
    error_message = "create must be one of: NOTHING, LOG_GROUP_ONLY, LOG_GROUP_AND_LOG_STREAM."
  }
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
  description = "Optional customer-managed KMS key ARN for CloudWatch log group encryption. When null, CloudWatch Logs uses AWS-managed encryption. Encryption at rest remains enabled either way."
}
