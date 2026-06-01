variable "create" {
  description = "Determines whether resources will be created."
  type        = bool
  default     = true
}

variable "node_type" {
  description = "The instance class used for the Redis replication group."
  type        = string
  default     = null

  validation {
    condition     = !var.create || var.node_type != null
    error_message = "node_type must be provided when create is true."
  }
}

variable "replication_group_id" {
  description = "Optional explicit replication group identifier. Defaults to the shared context-derived module ID."
  type        = string
  default     = null
}

variable "description" {
  description = "Optional description for the replication group."
  type        = string
  default     = null
}

variable "engine_version" {
  description = "Redis engine version. When create_parameter_group is true and parameter_group_family is unset, the major version is used to derive the family, for example redis7."
  type        = string
  default     = null
}

variable "apply_immediately" {
  description = "Whether modifications are applied immediately or during the next maintenance window."
  type        = bool
  default     = null
}

variable "auto_minor_version_upgrade" {
  description = "Whether ElastiCache minor engine upgrades are applied automatically during the maintenance window."
  type        = bool
  default     = null
}

variable "automatic_failover_enabled" {
  description = "Whether a read replica is promoted automatically if the primary fails."
  type        = bool
  default     = null
}

variable "multi_az_enabled" {
  description = "Whether to enable Multi-AZ for the replication group."
  type        = bool
  default     = false
}

variable "at_rest_encryption_enabled" {
  description = "Whether to enable encryption at rest."
  type        = bool
  default     = true
}

variable "transit_encryption_enabled" {
  description = "Whether to enable encryption in transit."
  type        = bool
  default     = true
}

variable "transit_encryption_mode" {
  description = "A setting that enables clients to migrate to in-transit encryption without downtime. Valid values are preferred and required."
  type        = string
  default     = null
}

variable "auth_token" {
  description = "Primary auth token input for Redis AUTH. This can only be set when transit_encryption_enabled is true."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.auth_token == null || var.redis_auth_token == null || var.auth_token == var.redis_auth_token
    error_message = "auth_token and redis_auth_token must match if both are set."
  }

  validation {
    condition     = (var.auth_token == null && var.redis_auth_token == null) || var.transit_encryption_enabled
    error_message = "An auth token can only be supplied when transit_encryption_enabled is true."
  }
}

variable "redis_auth_token" {
  description = "Compatibility alias for auth_token used by the older bespoke elasticache module."
  type        = string
  default     = null
  sensitive   = true
}

variable "auth_token_update_strategy" {
  description = "Strategy to use when updating the auth token. Valid values are SET, ROTATE, and DELETE."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN for encryption at rest."
  type        = string
  default     = null
}

variable "cluster_mode_enabled" {
  description = "Whether to enable Redis cluster mode."
  type        = bool
  default     = false
}

variable "cluster_mode" {
  description = "Optional cluster mode string. Valid values are enabled, disabled, or compatible."
  type        = string
  default     = null
}

variable "num_cache_clusters" {
  description = "Number of cache clusters in the replication group when cluster mode is disabled."
  type        = number
  default     = null
}

variable "num_node_groups" {
  description = "Number of node groups or shards when cluster mode is enabled."
  type        = number
  default     = null
}

variable "replicas_per_node_group" {
  description = "Number of replica nodes in each node group when cluster mode is enabled."
  type        = number
  default     = null
}

variable "data_tiering_enabled" {
  description = "Whether to enable data tiering. This is only valid for r6gd node types."
  type        = bool
  default     = null
}

variable "final_snapshot_identifier" {
  description = "Optional final snapshot identifier used when the replication group is destroyed."
  type        = string
  default     = null
}

variable "ip_discovery" {
  description = "IP version advertised in the discovery protocol. Valid values are ipv4 and ipv6."
  type        = string
  default     = null
}

variable "log_delivery_configuration" {
  description = "Log delivery configuration forwarded to the upstream module. Defaults to a slow-log CloudWatch Logs target when left empty."
  type        = any
  default     = {}
}

variable "maintenance_window" {
  description = "Weekly maintenance window in UTC using the format ddd:hh24:mi-ddd:hh24:mi."
  type        = string
  default     = null
}

variable "network_type" {
  description = "IP versions for cache connections. Valid values are ipv4, ipv6, or dual_stack."
  type        = string
  default     = null
}

variable "notification_topic_arn" {
  description = "ARN of an SNS topic to receive ElastiCache notifications."
  type        = string
  default     = null
}

variable "port" {
  description = "Redis listener port. Defaults to the upstream module default of 6379 when unset."
  type        = number
  default     = null

  validation {
    condition     = var.port == null || var.elasticache_port == null || var.port == var.elasticache_port
    error_message = "port and elasticache_port must match if both are set."
  }
}

variable "elasticache_port" {
  description = "Compatibility alias for port used by older calling code."
  type        = number
  default     = null
}

variable "preferred_cache_cluster_azs" {
  description = "Ordered list of availability zones for cache clusters in the replication group."
  type        = list(string)
  default     = []
}

variable "create_parameter_group" {
  description = "Whether to create a parameter group for the replication group."
  type        = bool
  default     = true
}

variable "parameter_group_name" {
  description = "Optional explicit parameter group name. Defaults to the replication group ID when a new parameter group is created."
  type        = string
  default     = null
}

variable "parameter_group_family" {
  description = "Parameter group family. When omitted, it is derived from the major engine_version if possible."
  type        = string
  default     = null

  validation {
    condition     = !var.create || !var.create_parameter_group || var.parameter_group_family != null || var.engine_version != null
    error_message = "When create_parameter_group is true, set parameter_group_family or provide engine_version so the family can be derived."
  }
}

variable "parameter_group_description" {
  description = "Optional description for the parameter group."
  type        = string
  default     = null
}

variable "parameters" {
  description = "List of parameter name and value maps forwarded to the upstream parameter group resource."
  type        = list(map(string))
  default     = []
}

variable "create_subnet_group" {
  description = "Whether to create a subnet group for the replication group."
  type        = bool
  default     = true
}

variable "subnet_group_name" {
  description = "Optional explicit subnet group name. Defaults to the replication group ID when a new subnet group is created."
  type        = string
  default     = null
}

variable "subnet_group_description" {
  description = "Optional description for the subnet group."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of private subnet IDs for the subnet group."
  type        = list(string)
  default     = []

  validation {
    condition     = !var.create || !var.create_subnet_group || length(var.subnet_ids) > 0
    error_message = "subnet_ids must contain at least one subnet when create_subnet_group is true."
  }
}

variable "create_security_group" {
  description = "Whether to create a security group for the replication group."
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "Optional explicit security group name. Defaults to the replication group ID when a new security group is created."
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "Optional description for the created security group."
  type        = string
  default     = null
}

variable "security_group_use_name_prefix" {
  description = "Whether the security group name should be used as a prefix instead of a fixed name."
  type        = bool
  default     = false
}

variable "security_group_ids" {
  description = "Existing security group IDs to attach in addition to any security group created by this module."
  type        = list(string)
  default     = []
}

variable "security_group_names" {
  description = "Existing security group names to associate with the replication group."
  type        = list(string)
  default     = []
}

variable "security_group_rules" {
  description = "Ingress and egress security-group rules forwarded to the upstream module."
  type        = any
  default     = {}
}

variable "security_group_tags" {
  description = "Additional tags applied only to the created security group."
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID used when creating the ElastiCache security group."
  type        = string
  default     = null

  validation {
    condition     = !var.create || !var.create_security_group || var.vpc_id != null
    error_message = "vpc_id must be provided when create_security_group is true."
  }
}

variable "snapshot_arns" {
  description = "List containing a Redis RDB snapshot ARN stored in S3 for restore operations."
  type        = list(string)
  default     = []
}

variable "snapshot_name" {
  description = "Name of an existing ElastiCache snapshot to restore from."
  type        = string
  default     = null
}

variable "snapshot_retention_limit" {
  description = "Number of days to retain automatic snapshots."
  type        = number
  default     = null
}

variable "snapshot_window" {
  description = "Daily UTC time range when automatic snapshots are taken, for example 05:00-09:00."
  type        = string
  default     = null
}

variable "timeouts" {
  description = "Custom create, update, and delete timeouts forwarded to the upstream module."
  type        = map(string)
  default     = {}
}

variable "user_group_ids" {
  description = "Optional user group IDs to associate with the replication group. Only one value is valid for Redis."
  type        = list(string)
  default     = null
}