################################################################
# S3-specific inputs.
#
# Naming, tagging and the master `enabled` switch come from
# context.tf via `module.this`.
################################################################

variable "bucket_name" {
  description = "Optional explicit bucket name. When null, the bucket is named `<module.this.id>-<region>` to keep S3's global namespace collision-free."
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Allow deletion of a non-empty bucket. Keep this disabled for any bucket that holds business data."
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Whether object versioning is enabled."
  type        = bool
  default     = true
}

variable "kms_master_key_arn" {
  description = "Optional KMS key ARN. When supplied, the default encryption switches from SSE-S3 (AES256) to SSE-KMS using this key, and PutObject calls referencing other KMS keys are denied."
  type        = string
  default     = null
}

variable "attach_deny_incorrect_kms_key_sse" {
  description = "Whether to attach a bucket policy statement denying PutObject calls that reference a KMS key other than `var.kms_master_key_arn`"
  type        = bool
  default     = null
}

variable "server_side_encryption_configuration" {
  description = "Optional full server-side encryption configuration map. When non-empty, this overrides the encryption defaults derived from `var.kms_master_key_arn`. See the upstream module's documentation for the expected shape."
  type        = any
  default     = {}
}

variable "logging" {
  description = <<-EOT
    Map describing access-log delivery to a target bucket. Leave as
    `{}` to disable logging. Example:
      logging = {
        target_bucket = "my-log-bucket"
        target_prefix = "s3/access-logs/"
      }
  EOT
  type        = any
  default     = {}
}

variable "policy" {
  description = "Optional custom bucket policy JSON document. The upstream module merges this with the deny-non-TLS and deny-unencrypted statements generated above."
  type        = string
  default     = null
}

variable "lifecycle_rule" {
  description = "List of lifecycle rules forwarded to the upstream module."
  type        = any
  default     = []
}

variable "cors_rule" {
  description = "List of CORS rules forwarded to the upstream module."
  type        = any
  default     = []
}
