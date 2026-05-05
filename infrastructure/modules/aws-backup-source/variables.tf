variable "project_name" {
  description = "The name of the project this relates to."
  type        = string
}

variable "environment_name" {
  description = "The name of the environment where AWS Backup is configured."
  type        = string
}
variable "nation" {
  description = "The nation this environment is for (e.g. en, ni)"
  type        = string
}

variable "notifications_target_email_address" {
  description = "The email address to which backup notifications will be sent via SNS."
  type        = string
  default     = ""
}

variable "notifications_sns_topic_arn" {
  description = "The ARN of the SNS topic to use for backup notifications."
  type        = string
  default     = ""
}

variable "enable_notifications" {
  description = "Flag to enable backup notifications."
  type        = bool
  default     = false
}

variable "bootstrap_kms_key_arn" {
  description = "The ARN of the bootstrap KMS key used for encryption at rest of the SNS topic."
  type        = string
}

variable "reports_bucket" {
  description = "Bucket to drop backup reports into"
  type        = string
}

variable "terraform_role_arn" {
  description = "ARN of Terraform role used to deploy to account (deprecated, please swap to terraform_role_arns)"
  type        = string
  default     = ""
}

variable "terraform_role_arns" {
  description = "ARN of Terraform roles used to deploy to account, defaults to caller arn if list is empty"
  type        = list(string)
  default     = []
}

variable "deletion_allowed_principal_arns" {
  description = "List of ARNs of principals allowed to delete backups."
  type        = list(string)
  default     = null
  nullable    = true
}

variable "destination_vault_retention_period" {
  description = "Retention period for recovery points made with the copy job lambda"
  type        = number
  default     = 365
}

variable "restore_testing_plan_algorithm" {
  description = "Algorithm of the Recovery Selection Point"
  type        = string
  default     = "LATEST_WITHIN_WINDOW"
}

variable "restore_testing_plan_start_window" {
  description = "Start window from the scheduled time during which the test should start"
  type        = number
  default     = 1
}

variable "restore_testing_plan_scheduled_expression" {
  description = "Scheduled Expression of Recovery Selection Point"
  type        = string
  default     = "cron(0 1 ? * SUN *)"
}

variable "restore_testing_plan_recovery_point_types" {
  description = "Recovery Point Types"
  type        = list(string)
  default     = ["SNAPSHOT"]
}

variable "restore_testing_plan_selection_window_days" {
  description = "Selection window days"
  type        = number
  default     = 7
}

variable "backup_copy_vault_arn" {
  description = "The ARN of the destination backup vault for cross-account backup copies."
  type        = string
  default     = ""
}

variable "backup_copy_vault_account_id" {
  description = "The account id of the destination backup vault for allowing restores back into the source account."
  type        = string
  default     = ""
}

variable "name_prefix" {
  description = "Name prefix for vault resources"
  type        = string
  default     = null
  validation {
    condition     = var.name_prefix == null || can(regex("^[^0-9]*$", var.name_prefix))
    error_message = "The name_prefix must not contain any numbers."
  }
}

variable "backup_plan_config_rds" {
  description = "Configuration for backup plans with RDS"
  type = object({
    enable              = bool
    selection_tag       = string
    selection_tag_value = optional(string)
    selection_tags = optional(list(object({
      key   = optional(string)
      value = optional(string)
    })))
    compliance_resource_types = list(string)
    restore_testing_overrides = optional(map(string))
    validation_window_hours   = optional(number)
    rules = optional(list(object({
      name                     = string
      schedule                 = string
      completion_window        = optional(number)
      enable_continuous_backup = optional(bool)
      lifecycle = object({
        delete_after       = number
        cold_storage_after = optional(number)
      })
      copy_action = optional(object({
        delete_after = optional(number)
      }))
    })))
  })
  default = {
    enable                    = true
    selection_tag             = "BackupRDS"
    selection_tag_value       = "True"
    selection_tags            = []
    compliance_resource_types = ["RDS"]
    validation_window_hours   = 1
    rules = [
      {
        name              = "rds_daily_kept_5_weeks"
        schedule          = "cron(0 0 * * ? *)"
        completion_window = 24
        lifecycle = {
          delete_after = 35
        }
        copy_action = {
          delete_after = 365
        }
      },
      {
        name              = "rds_weekly_kept_3_months"
        schedule          = "cron(0 1 ? * SUN *)"
        completion_window = 48
        lifecycle = {
          delete_after = 90
        }
        copy_action = {
          delete_after = 365
        }
      },
      {
        name              = "rds_monthly_kept_7_years"
        schedule          = "cron(0 2 1  * ? *)"
        completion_window = 72
        lifecycle = {
          cold_storage_after = 30
          delete_after       = 2555
        }
        copy_action = {
          delete_after = 365
        }
      }
    ]
  }
}

variable "iam_role_permissions_boundary" {
  description = "Optional permissions boundary ARN for backup role"
  type        = string
  default     = "" # Empty by default
}

variable "api_endpoint" {
  description = "API endpoint to send post build version notifications to"
  type        = string
  default     = ""
}

variable "lambda_copy_recovery_point_enable" {
  description = "Flag to enable the copy recovery point lambda (copy recovery point from destination vault back to source)."
  type        = bool
  default     = false
}

variable "lambda_copy_recovery_point_poll_interval_seconds" {
  description = "Polling interval in seconds for copy job status checks."
  type        = number
  default     = 30
}

variable "lambda_copy_recovery_point_max_wait_minutes" {
  description = "Maximum number of minutes to wait for a copy job to reach a terminal state before returning running status."
  type        = number
  default     = 10
}

variable "lambda_copy_recovery_point_destination_vault_arn" {
  description = "Destination vault ARN containing the recovery point to be copied back (the air-gapped vault)."
  type        = string
  default     = ""
}

variable "api_token" {
  description = "API token to authenticate with the API endpoint"
  type        = string
  default     = ""
}

variable "lambda_copy_recovery_point_source_vault_arn" {
  description = "Source vault ARN to which the recovery point will be copied back."
  type        = string
  default     = ""
}

variable "lambda_copy_recovery_point_assume_role_arn" {
  description = "ARN of role in destination account the lambda assumes to initiate the copy job (if required for cross-account)."
  type        = string
  default     = ""
}

# Restore Validation Variables
variable "restore_validation_enable" {
  description = "Enable automated validation of restored RDS instances during backup restore testing"
  type        = bool
  default     = false
}

variable "restore_validation_db_credentials_secret_name" {
  description = "Name of the Secrets Manager secret containing database credentials for connectivity testing"
  type        = string
}

variable "restore_validation_expected_subnet_pattern" {
  description = "Expected pattern in the DB subnet group name for configuration validation"
  type        = string
}

variable "restore_validation_timeout_seconds" {
  description = "Timeout for the restore validation Lambda function in seconds"
  type        = number
  default     = 300
}

variable "restore_validation_log_retention_days" {
  description = "Number of days to retain restore validation Lambda logs"
  type        = number
  default     = 30
}

variable "python_version" {
  description = "The Python version to use for the Lambda function"
  type        = string
  default     = "3.12"
}

variable "restore_testing_db_name" {
  description = "Name of the database to use for restore validation"
  type        = string
}
