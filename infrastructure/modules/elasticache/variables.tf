################################################################
# ElastiCache-specific inputs.
#
# Naming, tagging and the master `enabled` switch come from
# context.tf via `module.this`.
################################################################

variable "engine" {
  description = "ElastiCache engine. Supported: 'valkey' (recommended), 'redis', 'memcached'."
  type        = string
  default     = "valkey"

  validation {
    condition     = contains(["valkey", "redis", "memcached"], lower(var.engine))
    error_message = "Engine must be one of: valkey, redis, memcached"
  }
}
variable "deployment_mode" {
  description = <<-EOT
    Controls which ElastiCache resource type is created.
    - replication_group (default): HA replication group with optional cluster mode and Multi-AZ.
      Supports Valkey, Redis, and Memcached. Recommended for production and session storage.
    - cluster: Standalone single/multi-node cluster without replication.
      Useful for development, non-prod cost saving, or Memcached deployments.
    - serverless: Auto-scaling serverless cache. Valkey and Redis only.
      No node provisioning required; capacity scales on demand.
    Note: Memcached only supports deployment_mode = "cluster".
  EOT
  type        = string
  default     = "replication_group"

  validation {
    condition     = contains(["replication_group", "cluster", "serverless"], var.deployment_mode)
    error_message = "deployment_mode must be one of: replication_group, cluster, serverless"
  }
}


variable "engine_version" {
  description = <<-EOT
    Engine version.
    - Valkey: 7.2, 8.0
    - Redis: 7.0, 7.1, 7.2 (or 6.x for older deployments; 6.0+ required for data tiering)
    - Memcached: 1.6.x, 1.7.x
  EOT
  type        = string

  validation {
    condition     = can(regex("^\\d+\\.\\d+", var.engine_version))
    error_message = "Engine version must be in format X.Y or X.Y.Z"
  }
}

variable "node_type" {
  description = <<-EOT
    Node instance type.
    - Valkey/Redis: cache.t3.*, cache.t4g.*, cache.r6g.*, cache.r7g.*, cache.m6g.*, cache.m7g.*, etc.
    - Memcached: cache.t3.*, cache.t4g.*, cache.m6g.*, etc.

    Use cache.t3.small or cache.t4g.small for development; cache.r7g.* for production.
  EOT
  type        = string
  default     = null # Not required for deployment_mode = "serverless"

  validation {
    condition     = var.node_type == null || can(regex("^cache\\.[a-z0-9]+\\.[a-z0-9]+", var.node_type))
    error_message = "node_type must be a valid ElastiCache instance type (e.g. cache.r7g.large) or null for serverless."
  }
}

variable "num_cache_nodes" {
  description = "Number of cache nodes in the cluster. For non-cluster mode only; ignored when cluster_mode_enabled = true."
  type        = number
  default     = 2

  validation {
    condition     = var.num_cache_nodes >= 1 && var.num_cache_nodes <= 500
    error_message = "num_cache_nodes must be between 1 and 500"
  }
}

variable "az_mode" {
  description = <<-EOT
    Availability zone mode for standalone clusters (deployment_mode = "cluster").
    - single-az (default): all nodes in one AZ.
    - cross-az: nodes spread across multiple AZs. Required for Memcached multi-node clusters.
    Ignored for replication_group and serverless deployment modes.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.az_mode == null || contains(["single-az", "cross-az"], var.az_mode)
    error_message = "az_mode must be null, single-az, or cross-az"
  }
}

variable "cluster_mode_enabled" {
  description = <<-EOT
    Enable cluster mode (sharding). When true, all nodes in each shard store the full dataset.
    Allows horizontal scaling via multiple shards.
    Default: true (recommended for production).
  EOT
  type        = bool
  default     = true
}

variable "num_node_groups" {
  description = "Number of shards in cluster mode. Only used when cluster_mode_enabled = true. Minimum 1, maximum 500."
  type        = number
  default     = 1

  validation {
    condition     = var.num_node_groups >= 1 && var.num_node_groups <= 500
    error_message = "num_node_groups must be between 1 and 500"
  }
}

variable "replicas_per_node_group" {
  description = <<-EOT
    Number of replicas per shard (cluster mode) or per replication group (disabled cluster mode).
    Each replica stores a copy of the dataset for high availability and failover.
    Default: 2 (recommended for multi-AZ production deployments).
  EOT
  type        = number
  default     = 2

  validation {
    condition     = var.replicas_per_node_group >= 0 && var.replicas_per_node_group <= 5
    error_message = "replicas_per_node_group must be between 0 and 5"
  }
}



variable "multi_az_enabled" {
  description = "Enable Multi-AZ failover. Recommended for production deployments."
  type        = bool
  default     = true
}

variable "automatic_failover_enabled" {
  description = "Enable automatic failover for Redis/Valkey replication groups. Default: true"
  type        = bool
  default     = true
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades during maintenance window."
  type        = bool
  default     = true
}

variable "port" {
  description = "Port on which ElastiCache listens. Default: 6379 for Redis/Valkey, 11211 for Memcached. Must match between clients and cache."
  type        = number
  default     = 6379

  validation {
    condition     = var.port > 0 && var.port <= 65535
    error_message = "Port must be between 1 and 65535"
  }
}

# ================================================================
# Encryption (enforced)
# ================================================================

variable "kms_key_arn" {
  description = <<-EOT
    Optional KMS key ARN for encryption at rest. When null, AWS-managed encryption is used.
    To use a specific customer-managed KMS key, provide the ARN.
    Encryption at rest is always enforced.
  EOT
  type        = string
  default     = null
}

variable "auth_token" {
  description = <<-EOT
    Authentication token for Redis/Valkey clusters (16-128 characters, alphanumeric only).
    Required for Redis/Valkey; ignored for Memcached.
    Rotate regularly; use AWS Secrets Manager or similar.
  EOT
  type        = string
  sensitive   = true
  default     = null
}

# ================================================================
# Backup & Snapshot Configuration
# ================================================================

variable "snapshot_retention_days" {
  description = <<-EOT
    Number of days to retain automated snapshots (Redis/Valkey only).
    Memcached does not support snapshots.
    Range: 1 to 35 days. Default: 5 days.
  EOT
  type        = number
  default     = 5

  validation {
    condition     = var.snapshot_retention_days >= 1 && var.snapshot_retention_days <= 35
    error_message = "snapshot_retention_days must be between 1 and 35"
  }
}

variable "snapshot_window" {
  description = <<-EOT
    Time window in UTC when snapshots are taken (Redis/Valkey only).
    Format: hh24:mi-hh24:mi (e.g. '03:00-05:00'). Default: '03:00-05:00'
  EOT
  type        = string
  default     = "03:00-05:00"

  validation {
    condition     = can(regex("^[0-2][0-9]:[0-5][0-9]-[0-2][0-9]:[0-5][0-9]$", var.snapshot_window))
    error_message = "snapshot_window must be in format hh24:mi-hh24:mi"
  }
}

variable "final_snapshot_identifier_prefix" {
  description = "Prefix for the final snapshot name. When deletion is requested, a snapshot is created before deletion. Leave null to skip final snapshot."
  type        = string
  default     = null
}

variable "data_tiering_enabled" {
  description = <<-EOT
    Enable data tiering (Redis 6.0+ with r6gd/r7gd instances only).
    Allows overflow data to be stored on local NVMe SSD for cost savings.
    Default: false
  EOT
  type        = bool
  default     = false
}

# ================================================================
# Networking
# ================================================================

variable "vpc_id" {
  description = "VPC ID. Required when create_security_group = true; otherwise optional."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = <<-EOT
    List of subnet IDs for the ElastiCache subnet group.
    Should be private subnets across multiple AZs for high availability.
    Minimum: 2 subnets (different AZs); recommended for multi-AZ deployments.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "At least one subnet ID must be provided"
  }
}

variable "create_security_group" {
  description = <<-EOT
    When false (default), supply existing security group IDs via security_group_ids — e.g.
    from this repo's security-group module (feature/BCSS-23606-security-group-module).
    When true, the upstream module creates a security group in var.vpc_id using the
    rules defined in security_group_rules. vpc_id is required in this case.
  EOT
  type        = bool
  default     = false
}

variable "security_group_ids" {
  description = <<-EOT
    List of existing security group IDs to associate with the cache.
    Required when create_security_group = false.
    Typically sourced from this repo's security-group module.
  EOT
  type        = list(string)
  default     = []
}

variable "security_group_rules" {
  description = <<-EOT
    Map of ingress and egress rules for the upstream-managed security group.
    Only used when create_security_group = true.
    See the upstream module documentation for the full shape of each rule entry.
  EOT
  type        = any
  default     = {}
}

# ================================================================
# Maintenance & Monitoring
# ================================================================

variable "maintenance_window" {
  description = <<-EOT
    Time window for routine maintenance (UTC).
    Format: ddd:hh24:mi-ddd:hh24:mi (e.g. 'sun:03:00-sun:05:00').
    Default: Sunday 03:00-05:00 UTC.
  EOT
  type        = string
  default     = "sun:03:00-sun:05:00"

  validation {
    condition     = can(regex("^(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]-(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]$", lower(var.maintenance_window)))
    error_message = "maintenance_window must be in format ddd:hh24:mi-ddd:hh24:mi"
  }
}

variable "notification_topic_arn" {
  description = "Optional SNS topic ARN for ElastiCache event notifications (failovers, updates, maintenance). Leave null to disable."
  type        = string
  default     = null
}

variable "apply_immediately" {
  description = "Apply parameter changes immediately instead of during the maintenance window. Default: false (safer, batches changes)."
  type        = bool
  default     = false
}

# ================================================================
# Logging
# ================================================================

variable "log_delivery_configuration" {
  description = <<-EOT
    Log delivery configuration passed to the upstream module.
    By default, both slow-log and engine-log are sent to CloudWatch Logs with
    365-day retention and JSON format. The upstream module creates the log groups.
    To pre-create log groups externally (e.g. via the cloudwatch module for KMS-encrypted
    groups or custom retention), set create_cloudwatch_log_group = false and supply
    the destination group name per entry. Set to {} to disable all logging.
  EOT
  type        = any
  default = {
    slow-log = {
      destination_type                       = "cloudwatch-logs"
      log_format                             = "json"
      cloudwatch_log_group_retention_in_days = 365
    }
    engine-log = {
      destination_type                       = "cloudwatch-logs"
      log_format                             = "json"
      cloudwatch_log_group_retention_in_days = 365
    }
  }
}

variable "serverless_cache_usage_limits" {
  description = <<-EOT
    Optional capacity limits for serverless caches (deployment_mode = "serverless").
    Leave as {} for on-demand auto-scaling with no hard limits. Example:
      serverless_cache_usage_limits = {
        data_storage    = { maximum = 100, unit = "GB" }
        ecpu_per_second = { maximum = 5000 }
      }
  EOT
  type        = any
  default     = {}
}
