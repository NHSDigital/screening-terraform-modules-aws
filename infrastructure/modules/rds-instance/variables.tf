variable "name" {
  description = "The name of the resource"
  type        = string
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
  default     = "16"
}

# tflint-ignore: terraform_unused_declarations
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

# tflint-ignore: terraform_unused_declarations
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

# tflint-ignore: terraform_unused_declarations
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

variable "performance_insights_retention_period" {
  description = "The number of days to retain Performance Insights data for"
  type        = number
  default     = 7
}

# tflint-ignore: terraform_unused_declarations
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
  default     = false
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

# tflint-ignore: terraform_unused_declarations
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

# tflint-ignore: terraform_unused_declarations
variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7
}

variable "name_prefix" {
  description = "The account, environment etc"
  type        = string
}

# tflint-ignore: terraform_unused_declarations
variable "aws_account_id" {
  sensitive   = true
  description = "The AWS account ID"
  type        = string
}

# tflint-ignore: terraform_unused_declarations
variable "environment" {
  description = "The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD"
  type        = string
}

# tflint-ignore: terraform_unused_declarations
variable "vpc_name" {
  description = "vpc name"
  type        = string
  default     = ""
}

variable "user" {
  description = "username for postgres instance to use"
  type        = string
  default     = "postgres"
}

variable "private_subnet_ids" {
  description = "A list of private subnets to use"
  type        = list(string)
}

variable "vpc_id" {
  description = "The id for the vpc"
  type        = string
}

variable "ecs_sg_id" {
  description = "The security group ID for the ECS service"
  type        = string
}

variable "recovery_window" {
  description = "The number of days that credentials should be retained for"
  type        = number
}

variable "secret_replication_regions" {
  description = "List of additional regions where created secrets should be replicated"
  type        = list(string)
}

variable "snapshot_identifier" {
  description = "Optional snapshot identifier to restore from (e.g. if on performance environent)"
  type        = string
  default     = ""
}

variable "database_insights_mode" {
  description = "Whether to set database insights mode to standard or advanced"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the RDS instance in addition to the default tags"
  type        = map(string)
  default     = {}
}
