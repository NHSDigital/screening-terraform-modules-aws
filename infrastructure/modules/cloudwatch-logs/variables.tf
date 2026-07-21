################################################################
# CloudWatch Logs submodule inputs.
#
# Naming, tagging and the master `enabled` switch come from
# context.tf via `module.this`.
################################################################

variable "log_group_name" {
  description = "Name of the CloudWatch log group. Defaults to `/<service>/<project>/<environment>/<stack>/<name>` derived from context."
  type        = string
  default     = null

  validation {
    condition     = var.log_group_name == null || can(regex("^/.*$"), var.log_group_name)
    error_message = "log_group_name must start with a forward slash, e.g. \"/bcss/website/prod/network/loadbalancer\"."
  }
}

variable "retention_in_days" {
  type        = number
  default     = 30
  description = "CloudWatch log group retention in days. Valid values: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653."

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.retention_in_days)
    error_message = "retention_in_days must be one of: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653."
  }
}

variable "kms_key_id" {
  type        = string
  default     = null
  description = <<-EOT
  Optional customer-managed KMS key ARN for CloudWatch log group encryption.

  When null, CloudWatch Logs uses AWS-managed encryption.

  Encryption at rest remains enabled either way.

  Please note, after the AWS KMS CMK is disassociated from the log group, AWS CloudWatch Logs stops encrypting newly ingested data for the log group.

  All previously ingested data remains encrypted, and AWS CloudWatch Logs requires permissions for the CMK whenever the encrypted data is requested.
  EOT
}

variable "stream_names" {
  default     = []
  type        = list(string)
  description = "Names of CloudWatch log streams to create within the log group. Empty list creates log group only (recommended for Lambda/ECS auto-managed streams)."

  validation {
    condition     = alltrue([for s in var.stream_names : can(regex("^[.\\-_/#A-Za-z0-9]+$", s))])
    error_message = "stream_names must contain only alphanumeric characters, '.', '-', '_', '/', and '#'."
  }
}

variable "log_group_class" {
  type        = string
  default     = null
  description = "Specified the log class of the log group. Valid values are 'STANDARD' or 'INFREQUENT_ACCESS'. When null, defaults to STANDARD. Use INFREQUENT_ACCESS for lower-cost archival of logs accessed infrequently."

  validation {
    condition     = var.log_group_class == null || contains(["STANDARD", "INFREQUENT_ACCESS"], var.log_group_class)
    error_message = "log_group_class must be 'STANDARD', 'INFREQUENT_ACCESS', or null."
  }
}

variable "skip_destroy" {
  type        = bool
  default     = null
  description = "When true, CloudWatch log group is removed from Terraform state but not deleted at destroy time. Prevents accidental deletion of log groups containing critical audit/compliance data. When null, log group is deleted with the module."
}
