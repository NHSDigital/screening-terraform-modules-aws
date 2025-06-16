variable "name" {
  description = "The name of the resource"
}

variable "rds_instance_class" {
  type        = string
  description = "The instance class for the RDS instance"
}

variable "rds_engine" {
  type        = string
  description = "The engine for the RDS instance"
  default     = "postgres"
}

variable "rds_engine_version" {
  type        = string
  description = "The engine version for the RDS instance"
  default     = "12.5"
}

variable "aws_secret_id" {
  type        = string
  description = "The name of the secret that holds the postgresql login details"
}

variable "storage" {
  description = "The storage size for the instance"
  default     = 100
  type        = string
}

variable "encryption" {
  description = "If encryption should be enabled"
  type        = bool
  default     = true
}

variable "storage_type" {
  description = "The type of storage used, options are 'standard', 'gp2', 'gp3', 'io1' or 'io2'"
  type        = string
  default     = "gp3"
}

variable "db_max_connections" {
  description = "how many connections are allowed"
  type        = number
  default     = 5000
}

variable "skip_final_snapshot" {
  description = "Should there be a snapshot taken when instance destroyed"
  type        = bool
  default     = false
}

variable "iops" {
  description = "specify the provisioned IOPS, cannot be used if gp3 storage allocation is below 400"
  type        = number
  default     = 3000
}

variable "port" {
  description = "The port the database will listen on"
  type        = number
  default     = 5432
}

variable "db_storage_encryption" {
  description = "Whether the database storage should be encrypted"
  type        = bool
  default     = true
}

variable "auto_minor_version_upgrade" {
  description = "Whether to automatically upgrade the database to the latest minor version"
  type        = bool
  default     = true
}

variable "copy_tags_to_snapshot" {
  description = "Whether to copy tags to database snapshots"
  type        = bool
  default     = true
}

variable "allocated_storage" {
  description = "The amount of storage to allocate to the database in GB"
  type        = number
  default     = 50
}

variable "monitoring_interval" {
  description = "The interval in seconds to monitor the database"
  type        = number
  default     = 10
}

variable "performance_insights_enabled" {
  description = "Whether to enable Performance Insights for the database"
  type        = bool
  default     = false
}

variable "enable_backup" {
  description = "Whether to enable automated backups for the database"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "The number of days to retain automated backups for"
  type        = number
  default     = 4
}

variable "backup_window" {
  description = "The time window to perform automated backups in UTC (HH:MM-HH:MM)"
  type        = string
  default     = "01:00-02:00"
}

variable "maintenance_window" {
  description = "The time window to perform maintenance on the database in UTC (Day:HH:MM-Day:HH:MM)"
  type        = string
  default     = "Tue:02:30-Tue:03:30"
}

variable "publicly_accessible" {
  description = "Whether the database is publicly accessible"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Whether to apply changes to the database immediately"
  type        = bool
  default     = true
}

variable "allow_major_version_upgrade" {
  description = "Whether to allow major version upgrades to the database"
  type        = bool
  default     = true
}

variable "multi_az" {
  description = "Whether to deploy the database in multiple Availability Zones"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection for the database"
  type        = bool
  default     = false
}

variable "is_temporary_shutdown" {
  description = "Whether the database is in a temporary shutdown state (not a standard AWS attribute)"
  type        = bool
  default     = false
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Which logs should be exported"
  type        = list(string)
  default     = ["postgresql"]
}

variable "ingress_cidr" {
  description = "a list of the cidr's that can access the postgresql instance"
  type        = list(string)
}

variable "name_prefix" {
  description = "The account, environment etc"
  type        = string
}

variable "aws_account_id" {
  sensitive   = true
  description = "The AWS account ID"
  type        = string
}

variable "environment" {
  description = "The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD"
  type        = string
}

variable "vpc_name" {
  description = "vpc name"
  type        = string
  default     = ""
}
