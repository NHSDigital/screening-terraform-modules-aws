# ----------------------------------------------------------------------------
# Instance identity
# ----------------------------------------------------------------------------

variable "identifier" {
  description = "Explicit identifier for the RDS instance. When set, overrides the name derived from context labels. Use this when migrating from an existing instance that already has a specific identifier, or when the context-derived name would be too long for RDS."
  type        = string
  default     = null
}

# ----------------------------------------------------------------------------
# Engine
# ----------------------------------------------------------------------------

variable "engine" {
  description = "The database engine to use (e.g. 'oracle-ee', 'postgres', 'mysql')"
  type        = string
}

variable "engine_version" {
  description = "The engine version to use"
  type        = string
}

variable "license_model" {
  description = "License model for the DB instance. Required for some engines (e.g. Oracle SE1 requires 'license-included')"
  type        = string
  default     = null
}

variable "character_set_name" {
  description = "Oracle character set name. Cannot be changed after creation. Must be null when restoring from a snapshot"
  type        = string
  default     = null
}

# ----------------------------------------------------------------------------
# Instance sizing
# ----------------------------------------------------------------------------

variable "instance_class" {
  description = "The instance type of the RDS instance (e.g. 'db.m5.large')"
  type        = string
}

variable "allocated_storage" {
  description = "The allocated storage in gibibytes"
  type        = number
}

variable "max_allocated_storage" {
  description = "Upper limit for storage autoscaling in gibibytes. Set to 0 to disable autoscaling"
  type        = number
  default     = 0
}

variable "storage_type" {
  description = "One of 'standard', 'gp2', 'gp3', 'io1', or 'io2'. Defaults to 'io1' when iops is set, otherwise 'gp2'"
  type        = string
  default     = null
}

variable "iops" {
  description = "Provisioned IOPS. Required when storage_type is 'io1' or 'io2'"
  type        = number
  default     = null
}

variable "kms_key_id" {
  description = "ARN of the KMS key for storage encryption. If omitted, the default account KMS key is used"
  type        = string
  default     = null
}

# ----------------------------------------------------------------------------
# Credentials
# ----------------------------------------------------------------------------

variable "username" {
  description = "Username for the master DB user"
  type        = string
  sensitive   = true
}

variable "password_wo" {
  description = "Write-only password for the master DB user. Required when manage_master_user_password is false and snapshot_identifier is not set"
  type        = string
  default     = null
  sensitive   = true
}

variable "password_wo_version" {
  description = "Increment this value to trigger a password rotation when password_wo changes"
  type        = number
  default     = 1
}

variable "manage_master_user_password" {
  description = "When true, RDS manages the master password in Secrets Manager. When false, password_wo must be provided"
  type        = bool
  default     = false
}

# ----------------------------------------------------------------------------
# Database
# ----------------------------------------------------------------------------

variable "db_name" {
  description = "The name of the database to create. Omit to skip initial database creation"
  type        = string
  default     = null
}

variable "port" {
  description = "The port on which the DB accepts connections"
  type        = number
}

# ----------------------------------------------------------------------------
# Networking
# ----------------------------------------------------------------------------

variable "subnet_ids" {
  description = "List of VPC subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs to associate with the instance. Create the security group using the dedicated security group module and pass its ID here"
  type        = list(string)
  default     = []
}

# ----------------------------------------------------------------------------
# Parameter group
# ----------------------------------------------------------------------------

variable "family" {
  description = "DB parameter group family (e.g. 'oracle-ee-19', 'postgres16', 'mysql8.0')"
  type        = string
}

variable "parameters" {
  description = "List of DB parameters to apply to the parameter group"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string)
  }))
  default = []
}

# ----------------------------------------------------------------------------
# Option group
# ----------------------------------------------------------------------------

variable "major_engine_version" {
  description = "Major engine version for the option group (e.g. '19' for Oracle 19c)"
  type        = string
}

variable "options" {
  description = "List of option group options to apply. See the community module documentation for the full object shape"
  type        = any
  default     = []
}

# ----------------------------------------------------------------------------
# Availability and backup
# ----------------------------------------------------------------------------

variable "multi_az" {
  description = "Specifies if the RDS instance is Multi-AZ"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups. Must be between 0 and 35"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Daily UTC time range for automated backups (e.g. '23:00-23:30'). Must not overlap with maintenance_window"
  type        = string
  default     = "23:00-23:30"
}

variable "maintenance_window" {
  description = "Weekly maintenance window (e.g. 'Sun:00:00-Sun:03:00')"
  type        = string
  default     = "Sun:00:00-Sun:03:00"
}

variable "skip_final_snapshot" {
  description = "If true, no final snapshot is created on deletion. Should be false in production"
  type        = bool
  default     = false
}

variable "snapshot_identifier" {
  description = "Snapshot ID to restore the instance from. When set, character_set_name must be null"
  type        = string
  default     = null
}

variable "apply_immediately" {
  description = "Apply modifications immediately rather than deferring to the next maintenance window"
  type        = bool
  default     = false
}

# ----------------------------------------------------------------------------
# Monitoring and performance
# ----------------------------------------------------------------------------

variable "monitoring_interval" {
  description = "Interval in seconds between Enhanced Monitoring data points. Valid values: 0, 1, 5, 10, 15, 30, 60. Set to 0 to disable"
  type        = number
  default     = 5

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval must be one of: 0, 1, 5, 10, 15, 30, 60."
  }
}

# Note: The Performance Insights console is transitioning to CloudWatch Database
# Insights (end-of-life July 31, 2026). Terraform API parameters are fully
# preserved and continue to work unchanged after the transition.
variable "performance_insights_enabled" {
  description = "Enable Performance Insights (Standard mode of CloudWatch Database Insights). When true, performance_insights_kms_key_id must also be set."
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Retention period for Performance Insights data in days. Valid values: 7, 731, or a multiple of 31"
  type        = number
  default     = 7

  validation {
    condition = (
      var.performance_insights_retention_period == 7 ||
      var.performance_insights_retention_period == 731 ||
      (var.performance_insights_retention_period % 31 == 0 && var.performance_insights_retention_period >= 31)
    )
    error_message = "performance_insights_retention_period must be 7, 731, or a multiple of 31 (e.g. 31, 62, 93)."
  }
}

variable "performance_insights_kms_key_id" {
  description = "ARN of the customer-managed KMS key used to encrypt Performance Insights data. Required when performance_insights_enabled is true. AWS-managed keys are not acceptable per platform policy."
  type        = string
  default     = null
}

# ----------------------------------------------------------------------------
# Lifecycle
# ----------------------------------------------------------------------------

variable "deletion_protection" {
  description = "Prevents the DB instance from being deleted when true. Should be true in production"
  type        = bool
  default     = true
}

variable "timeouts" {
  description = "Terraform resource management timeouts for the DB instance"
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}
