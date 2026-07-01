################################################################
# ElastiCache
#
# Thin NHS wrapper around the community
# terraform-aws-modules/elasticache/aws module that enforces
# the screening platform's baseline controls:
#
#   * Encryption in transit (TLS) — enforced
#   * Encryption at rest — enforced for all engines
#   * Multi-AZ with automatic failover — configurable
#   * Authentication — AUTH token required for Redis/Valkey
#   * VPC isolation — via security groups and subnet groups
#   * Logging — engine logs and slow logs to CloudWatch
#   * Backup and retention — configurable with sensible defaults
#   * No public access — clusters are private by default
#
# Naming and tagging are derived from context.tf via module.this.
#
# Supported engines: Valkey (recommended), Redis (5.0+), Memcached
# Deployment modes (var.deployment_mode):
#   replication_group — HA replication group; default; production recommended
#   cluster           — standalone single/multi-node cluster; lower cost dev/test
#   serverless        — auto-scaling serverless cache (Valkey/Redis only)
################################################################

################################################################
# ElastiCache
################################################################

module "elasticache" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "1.11.0"

  # Not used for serverless; that mode is handled by the separate module block below.
  create = module.this.enabled && !local.create_serverless_cache

  # ----------------------------------------------------------------
  # Control resource creation
  # ---------------------------------------------------------------- (driven by var.deployment_mode)
  create_cluster           = local.create_cluster
  create_replication_group = local.create_replication_group

  # ----------------------------------------------------------------
  # Engine and cluster configuration
  # ----------------------------------------------------------------
  engine         = var.engine
  engine_version = var.engine_version
  node_type      = var.node_type

  # Standalone cluster: simple primary (+ additional nodes for Memcached cross-az)
  num_cache_nodes = var.num_cache_nodes
  az_mode         = var.az_mode

  # Replication group without cluster mode: total count (primary + replicas)
  num_cache_clusters = local.create_replication_group && !var.cluster_mode_enabled ? var.num_cache_nodes : null

  # Cluster mode: shared dataset with shards (all nodes store full dataset)
  cluster_mode_enabled = var.cluster_mode_enabled

  # Replicas per node group (for cluster mode)
  replicas_per_node_group = var.cluster_mode_enabled ? var.replicas_per_node_group : null
  num_node_groups         = var.cluster_mode_enabled ? var.num_node_groups : null

  # Parameter group family (e.g. valkey8, redis7, memcached1.6)
  parameter_group_family = local.parameter_family

  # ----------------------------------------------------------------
  # Resource identifiers
  # ----------------------------------------------------------------
  replication_group_id = local.replication_group_id
  cluster_id           = local.cluster_id
  description          = local.replication_group_description

  # ----------------------------------------------------------------
  # Encryption: in transit (TLS) and at rest — ENFORCED
  # Neither is exposed as a variable; callers cannot weaken these.
  # ----------------------------------------------------------------
  transit_encryption_enabled = true
  transit_encryption_mode    = "required"
  at_rest_encryption_enabled = true
  kms_key_arn                = var.kms_key_arn

  # Authentication: AUTH token for Redis/Valkey
  auth_token                 = var.auth_token
  auth_token_update_strategy = "ROTATE"

  # ----------------------------------------------------------------
  # Automatic failover and availability
  # ----------------------------------------------------------------
  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  # ----------------------------------------------------------------
  # Maintenance and backup
  # ----------------------------------------------------------------
  maintenance_window     = var.maintenance_window
  notification_topic_arn = var.notification_topic_arn
  apply_immediately      = var.apply_immediately

  # Snapshots (for Redis/Valkey only; ignored for Memcached)
  snapshot_window           = var.snapshot_window
  snapshot_retention_limit  = var.snapshot_retention_days
  final_snapshot_identifier = var.final_snapshot_identifier_prefix != null ? "${var.final_snapshot_identifier_prefix}-${local.final_snapshot_id}" : null

  # Data tiering (for Redis 6.0+; requires r6gd instances)
  data_tiering_enabled = var.data_tiering_enabled

  # ----------------------------------------------------------------
  # Networking
  # ----------------------------------------------------------------
  # Subnet group: created by upstream module using subnet_ids
  create_subnet_group = true
  subnet_ids          = var.subnet_ids
  vpc_id              = var.vpc_id

  # Security group:
  create_security_group = false
  security_group_ids    = var.security_group_ids

  # Port configuration
  port = var.port

  # ----------------------------------------------------------------
  # Logging: engine logs and slow logs to CloudWatch
  # ----------------------------------------------------------------
  # Two scenarios are supported:
  #   a) var.log_delivery_configuration = null (default): the upstream module
  #      creates and owns the log groups using the default config with distinct
  #      names per log type (/aws/elasticache/<id>/slow-log and engine-log).
  #   b) var.log_delivery_configuration is set: the caller provides the full config.
  #      Set create_cloudwatch_log_group = false if log groups are managed externally,
  #      or true if the upstream module should create them.
  # Under no circumstances does the ElastiCache service itself create log groups.
  log_delivery_configuration = var.log_delivery_configuration != null ? var.log_delivery_configuration : local.default_log_delivery_configuration

  tags = module.this.tags

}

# ================================================================
# Serverless Cache (deployment_mode = "serverless")
# ================================================================
module "elasticache_serverless" {
  source  = "terraform-aws-modules/elasticache/aws//modules/serverless-cache"
  version = "1.11.0"

  create = module.this.enabled && local.create_serverless_cache

  cache_name           = local.replication_group_id
  engine               = var.engine
  major_engine_version = local.major_engine_version
  description          = local.replication_group_description

  # Encryption at rest — ENFORCED; pass in from the kms module or null for AWS-managed
  kms_key_id = var.kms_key_arn

  # Networking: pass security_group_ids from the security-group module.
  # create_security_group above does not affect the serverless module.
  security_group_ids = var.security_group_ids
  subnet_ids         = var.subnet_ids

  # Backup (Redis only; ignored for Valkey)
  snapshot_retention_limit = var.snapshot_retention_days
  daily_snapshot_time      = local.serverless_snapshot_time

  # Optional capacity limits (data_storage and ecpu_per_second).
  # Leave as {} for on-demand auto-scaling with no hard limits.
  cache_usage_limits = var.serverless_cache_usage_limits

  tags = module.this.tags
}
