################################################################
# Patch baseline
################################################################

variable "operating_system" {
  description = "Operating system the patch baseline applies to. Must match the OS of the EC2 instances being targeted."
  type        = string
  default     = "AMAZON_LINUX_2"

  validation {
    condition     = contains(["WINDOWS", "AMAZON_LINUX", "AMAZON_LINUX_2", "AMAZON_LINUX_2022", "AMAZON_LINUX_2023", "UBUNTU", "REDHAT_ENTERPRISE_LINUX", "SUSE", "CENTOS", "ORACLE_LINUX", "DEBIAN", "RASPBIAN", "ROCKY_LINUX", "ALMA_LINUX"], var.operating_system)
    error_message = "operating_system must be a valid SSM-supported OS identifier."
  }
}

variable "approved_patches_compliance_level" {
  description = "Severity of the compliance violation when an approved patch is missing. Valid values: CRITICAL, HIGH, MEDIUM, LOW, INFORMATIONAL, UNSPECIFIED."
  type        = string
  default     = "HIGH"

  validation {
    condition     = contains(["CRITICAL", "HIGH", "MEDIUM", "LOW", "INFORMATIONAL", "UNSPECIFIED"], var.approved_patches_compliance_level)
    error_message = "approved_patches_compliance_level must be one of CRITICAL, HIGH, MEDIUM, LOW, INFORMATIONAL, UNSPECIFIED."
  }
}

variable "patch_baseline_approval_rules" {
  description = "Approval rules for the patch baseline. Each rule controls which patches are automatically approved. approve_after_days and approve_until_date are mutually exclusive within a rule."
  type = list(object({
    approve_after_days  = optional(number)
    approve_until_date  = optional(string)
    compliance_level    = string
    enable_non_security = bool
    patch_baseline_filters = list(object({
      name   = string
      values = list(string)
    }))
  }))
  default = [
    {
      approve_after_days  = 7
      compliance_level    = "HIGH"
      enable_non_security = true
      patch_baseline_filters = [
        {
          name   = "PRODUCT"
          values = ["AmazonLinux2", "AmazonLinux2.0"]
        },
        {
          name   = "CLASSIFICATION"
          values = ["Security", "Bugfix"]
        },
        {
          name   = "SEVERITY"
          values = ["Critical", "Important"]
        }
      ]
    }
  ]
}

################################################################
# Install maintenance window
################################################################

variable "install_maintenance_window_schedule" {
  description = "Cron or rate expression for the patch install maintenance window, e.g. cron(0 0 21 ? * WED *)."
  type        = string
  default     = null
}

variable "install_maintenance_window_duration" {
  description = "Duration of the install maintenance window in hours."
  type        = number
  default     = 3
}

variable "install_maintenance_window_cutoff" {
  description = "Number of hours before the install window ends at which SSM stops scheduling new tasks."
  type        = number
  default     = 1
}

variable "install_maintenance_windows_targets" {
  description = "List of target definitions (key/values tag pairs) identifying which EC2 instances the install window applies to."
  type = list(object({
    key    = string
    values = list(string)
  }))
  default = []
}

variable "install_patch_groups" {
  description = "List of patch group names to register with the install maintenance window."
  type        = list(string)
  default     = []
}

################################################################
# Scan maintenance window
################################################################

variable "scan_maintenance_window_schedule" {
  description = "Cron or rate expression for the patch scan maintenance window, e.g. cron(0 0 18 ? * WED *)."
  type        = string
  default     = null
}

variable "scan_maintenance_window_duration" {
  description = "Duration of the scan maintenance window in hours."
  type        = number
  default     = 3
}

variable "scan_maintenance_window_cutoff" {
  description = "Number of hours before the scan window ends at which SSM stops scheduling new tasks."
  type        = number
  default     = 1
}

variable "scan_maintenance_windows_targets" {
  description = "List of target definitions (key/values tag pairs) identifying which EC2 instances the scan window applies to."
  type = list(object({
    key    = string
    values = list(string)
  }))
  default = []
}

variable "scan_patch_groups" {
  description = "List of patch group names to register with the scan maintenance window."
  type        = list(string)
  default     = []
}

################################################################
# Task execution
################################################################

variable "reboot_option" {
  description = "Reboot behaviour after patch installation. RebootIfNeeded reboots only if new patches were installed or patches are pending reboot. NoReboot skips reboot entirely."
  type        = string
  default     = "RebootIfNeeded"

  validation {
    condition     = contains(["RebootIfNeeded", "NoReboot"], var.reboot_option)
    error_message = "reboot_option must be either RebootIfNeeded or NoReboot."
  }
}

variable "service_role_arn" {
  description = "ARN of the IAM role SSM assumes when running maintenance window tasks. If null, SSM uses the account service-linked role."
  type        = string
  default     = null
}

variable "max_concurrency" {
  description = "Maximum number of targets the task runs against in parallel."
  type        = number
  default     = 20
}

variable "max_errors" {
  description = "Maximum number of errors allowed before the task stops being scheduled."
  type        = number
  default     = 50
}

################################################################
# Logging
################################################################

variable "s3_log_output_enabled" {
  description = "Write patch task output to an S3 bucket. Recommended for audit and compliance."
  type        = bool
  default     = true
}

variable "bucket_id" {
  description = "ID of an existing S3 bucket to use for patch logs. Leave empty to have the module create a dedicated bucket."
  type        = list(string)
  default     = []
}

variable "s3_bucket_prefix_install_logs" {
  description = "S3 key prefix for install task logs."
  type        = string
  default     = "install"
}

variable "s3_bucket_prefix_scan_logs" {
  description = "S3 key prefix for scan task logs."
  type        = string
  default     = "scanning"
}
