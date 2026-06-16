# ----------------------------------------------------------------------------
# Engine
# ----------------------------------------------------------------------------

variable "engine" {
  description = "Cache engine. Valid values are redis and valkey"
  type        = string
  default     = "valkey"

  validation {
    condition     = contains(["redis", "valkey"], var.engine)
    error_message = "engine must be either redis or valkey."
  }
}

variable "engine_version" {
  description = "Engine version (e.g. '7.1'). Major version is used to derive parameter_group_family when not set explicitly"
  type        = string

  validation {
    condition     = !can(regex("^[45](\\.|$)", var.engine_version))
    error_message = "Redis OSS major versions 4 and 5 are out of standard support. Use Valkey or Redis OSS 6+."
  }
}

# ----------------------------------------------------------------------------
# Instance identity
# ----------------------------------------------------------------------------

variable "replication_group_id" {
  description = "Explicit replication group identifier. Defaults to module.this.id from context"
  type        = string
  default     = null
}

variable "description" {
  description = "Description for the replication group"
  type        = string
  default     = null
}

# ----------------------------------------------------------------------------
# Instance sizing
# ----------------------------------------------------------------------------

variable "node_type" {
  description = "The instance class for cache nodes (e.g. 'cache.t3.micro', 'cache.r6g.large')"
  type        = string
}

variable "port" {
  description = "Port on which the cache accepts connections"
  type        = number
  default     = 6379
}

# ----------------------------------------------------------------------------
# Encryption and authentication
# ----------------------------------------------------------------------------

variable "auth_token" {
  description = "Auth token for Redis/Valkey AUTH. Transit encryption is always enabled in this module"
  type        = string
  default     = null
  sensitive   = true
}

variable "transit_encryption_mode" {
  description = "Setting to enable clients to migrate to in-transit encryption without downtime. Valid values: preferred, required"
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encryption at rest. If omitted, the default ElastiCache key is used"
  type        = string
  default     = null
}

# ----------------------------------------------------------------------------
# Cluster topology
# ----------------------------------------------------------------------------

variable "cluster_mode" {
  description = "Cluster mode setting. Valid values: enabled, disabled, compatible"
  type        = string
  default     = null
}

variable "num_cache_clusters" {
  description = "Number of cache clusters when cluster mode is disabled"
  type        = number
  default     = null
}

variable "num_node_groups" {
  description = "Number of node groups (shards) when cluster mode is enabled"
  type        = number
  default     = null
}

variable "replicas_per_node_group" {
  description = "Number of replica nodes per node group when cluster mode is enabled"
  type        = number
  default     = null
}

# ----------------------------------------------------------------------------
# Availability
# ----------------------------------------------------------------------------

variable "automatic_failover_enabled" {
  description = "Whether a read replica is promoted automatically if the primary fails"
  type        = bool
  default     = null
}

variable "multi_az_enabled" {
  description = "Whether to enable Multi-AZ for the replication group"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Whether modifications are applied immediately or during the next maintenance window"
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Whether minor engine upgrades are applied automatically during the maintenance window"
  type        = bool
  default     = null
}

variable "maintenance_window" {
  description = "Weekly maintenance window in UTC (e.g. 'Mon:00:00-Mon:03:00')"
  type        = string
  default     = null
}

# ----------------------------------------------------------------------------
# Networking
# ----------------------------------------------------------------------------

variable "security_group_ids" {
  description = "List of security group IDs to associate with the replication group. Create SGs externally using the security-group module"
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "List of private subnet IDs for the subnet group"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "subnet_ids must contain at least one subnet."
  }
}

variable "subnet_group_name" {
  description = "Explicit subnet group name. Defaults to the replication group ID"
  type        = string
  default     = null
}

variable "subnet_group_description" {
  description = "Description for the subnet group"
  type        = string
  default     = null
}

# ----------------------------------------------------------------------------
# Parameter group
# ----------------------------------------------------------------------------

variable "create_parameter_group" {
  description = "Whether to create a parameter group"
  type        = bool
  default     = true
}

variable "parameter_group_name" {
  description = "Explicit parameter group name. Defaults to the replication group ID"
  type        = string
  default     = null
}

variable "parameter_group_family" {
  description = "Parameter group family. When omitted, derived from engine + major engine_version (e.g. 'valkey7', 'redis7')"
  type        = string
  default     = null
}

variable "parameter_group_description" {
  description = "Description for the parameter group"
  type        = string
  default     = null
}

variable "parameters" {
  description = "List of parameter name/value maps for the parameter group"
  type        = list(map(string))
  default     = []
}

# ----------------------------------------------------------------------------
# Logging
# ----------------------------------------------------------------------------

variable "log_delivery_configuration" {
  description = "Log delivery configuration. Defaults to slow-log via CloudWatch Logs when empty"
  type        = any
  default     = {}
}

variable "notification_topic_arn" {
  description = "ARN of an SNS topic to receive ElastiCache notifications"
  type        = string
  default     = null
}

# ----------------------------------------------------------------------------
# Snapshots
# ----------------------------------------------------------------------------

variable "snapshot_retention_limit" {
  description = "Number of days to retain automatic snapshots. 0 disables backups"
  type        = number
  default     = null
}

variable "snapshot_window" {
  description = "Daily UTC time range for automatic snapshots (e.g. '05:00-09:00')"
  type        = string
  default     = null
}

variable "final_snapshot_identifier" {
  description = "Final snapshot identifier when the replication group is destroyed"
  type        = string
  default     = null
}
