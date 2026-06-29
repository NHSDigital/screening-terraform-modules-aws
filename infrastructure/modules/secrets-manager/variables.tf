################################################################
# Secrets Manager-specific inputs.
#
# Naming, tagging and the master `enabled` switch come from
# context.tf via `module.this`.
#
# Inputs NOT exposed here (opinionated defaults hardcoded in main.tf):
#   - block_public_policy  → always true
#   - name / name_prefix   → derived from module.this.id via locals.tf
#   - secret_binary        → not supported; use secret_string
#   - replica              → replication not required for this use case
#   - version_stages       → low-value for standard use cases
################################################################

variable "secret_name" {
  type        = string
  default     = null
  description = "Optional explicit name for the secret. When null, the name is derived from context labels via module.this.id."
}

variable "description" {
  type        = string
  default     = null
  description = "A description of the secret as viewed in the AWS console."
}

variable "kms_key_id" {
  type        = string
  default     = null
  description = "ARN or ID of the KMS key used to encrypt the secret. Defaults to the AWS-managed key (aws/secretsmanager) when not set."
}

variable "recovery_window_in_days" {
  type        = number
  default     = 30
  description = "Number of days AWS Secrets Manager waits before permanently deleting the secret. Valid values: 0 (immediate deletion) or 7-30."
  validation {
    condition     = var.recovery_window_in_days == 0 || (var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30)
    error_message = "recovery_window_in_days must be 0 (immediate deletion) or between 7 and 30 inclusive."
  }
}

variable "create_random_password" {
  type        = bool
  default     = false
  description = "When true, generates a random password as the secret value. When set, secret_string and secret_string_wo should not be set."
}

variable "random_password_length" {
  type        = number
  default     = 32
  description = "The length of the randomly-generated password. Only used when create_random_password is true."
  validation {
    condition     = var.random_password_length >= 8 && var.random_password_length <= 4096
    error_message = "random_password_length must be between 8 and 4096 inclusive."
  }
}

variable "random_password_override_special" {
  type        = string
  default     = "!@#$%&*()-_=+[]{}<>:?"
  description = "Supply your own list of special characters for random password generation. Overrides the default special character set. Only used when create_random_password is true."
}

variable "secret_string" {
  type        = string
  default     = null
  sensitive   = true
  description = "The secret value to store as a plaintext string. Use jsonencode() to store structured data such as database credentials. Mutually exclusive with secret_string_wo."
}

variable "secret_string_wo" {
  type        = string
  default     = null
  sensitive   = true
  description = "Write-only variant of secret_string. The value is accepted by Terraform but never stored in state, making it safer for production secrets. Use jsonencode() for structured data. Mutually exclusive with secret_string."
}

variable "secret_string_wo_version" {
  type        = string
  default     = null
  description = "Trigger value used alongside secret_string_wo. Increment this (e.g. a timestamp or counter) whenever the secret value changes, so Terraform knows to push the new value."
}

variable "ignore_secret_changes" {
  type        = bool
  default     = false
  description = "When true, Terraform will ignore any changes made to the secret value outside of Terraform (e.g. by a rotation Lambda). Set to true when rotation is enabled."
}

variable "create_policy" {
  type        = bool
  default     = false
  description = "Whether to attach a resource-based policy to the secret."
}

variable "policy_statements" {
  type = map(object({
    sid           = optional(string)
    actions       = optional(list(string))
    not_actions   = optional(list(string))
    effect        = optional(string)
    resources     = optional(list(string))
    not_resources = optional(list(string))
    principals = optional(list(object({
      type        = string
      identifiers = list(string)
    })))
    not_principals = optional(list(object({
      type        = string
      identifiers = list(string)
    })))
    condition = optional(list(object({
      test     = string
      values   = list(string)
      variable = string
    })))
  }))
  default     = {}
  description = "A map of IAM policy statements to attach to the secret policy. Only used when create_policy is true."
}

variable "enable_rotation" {
  type        = bool
  default     = false
  description = "Whether to enable automatic secret rotation via a Lambda function."
}

variable "rotate_immediately" {
  type        = bool
  default     = null
  description = "When enable_rotation is true, specifies whether to rotate the secret immediately or wait until the next scheduled rotation window. Defaults to immediate rotation when not set."
}

variable "rotation_lambda_arn" {
  type        = string
  default     = ""
  description = "ARN of the Lambda function that rotates the secret. Required when enable_rotation is true."
}

variable "rotation_rules" {
  type = object({
    automatically_after_days = optional(number)
    duration                 = optional(string)
    schedule_expression      = optional(string)
  })
  default     = null
  description = "Rotation schedule for the secret. Provide either automatically_after_days or a schedule_expression (cron/rate). Required when enable_rotation is true."
}
