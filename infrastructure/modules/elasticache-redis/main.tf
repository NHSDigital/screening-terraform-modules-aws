locals {
  replication_group_id = coalesce(var.replication_group_id, module.this.id)
  resolved_auth_token  = try(coalesce(var.auth_token, var.redis_auth_token), null)
  resolved_port        = try(coalesce(var.port, var.elasticache_port), null)
  engine_version_major = try(regex("^\\d+", var.engine_version), null)

  parameter_group_family = coalesce(
    var.parameter_group_family,
    local.engine_version_major != null ? "redis${local.engine_version_major}" : null
  )

  log_delivery_configuration = length(var.log_delivery_configuration) > 0 ? var.log_delivery_configuration : {
    slow-log = {
      destination_type = "cloudwatch-logs"
      log_format       = "json"
    }
  }
}

module "elasticache" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "1.11.0"

  create                   = module.this.enabled && var.create
  create_cluster           = false
  create_replication_group = true

  engine               = "redis"
  replication_group_id = local.replication_group_id
  description          = coalesce(var.description, "${local.replication_group_id} redis replication group")

  apply_immediately          = var.apply_immediately
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled

  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  transit_encryption_mode    = var.transit_encryption_mode
  auth_token                 = local.resolved_auth_token
  auth_token_update_strategy = var.auth_token_update_strategy
  kms_key_arn                = var.kms_key_arn

  cluster_mode            = var.cluster_mode
  cluster_mode_enabled    = var.cluster_mode_enabled
  num_cache_clusters      = var.num_cache_clusters
  num_node_groups         = var.num_node_groups
  replicas_per_node_group = var.replicas_per_node_group

  data_tiering_enabled           = var.data_tiering_enabled
  engine_version                 = var.engine_version
  final_snapshot_identifier      = var.final_snapshot_identifier
  ip_discovery                   = var.ip_discovery
  log_delivery_configuration     = local.log_delivery_configuration
  maintenance_window             = var.maintenance_window
  network_type                   = var.network_type
  node_type                      = var.node_type
  notification_topic_arn         = var.notification_topic_arn
  parameter_group_description    = var.parameter_group_description
  parameter_group_family         = coalesce(local.parameter_group_family, "")
  parameter_group_name           = coalesce(var.parameter_group_name, local.replication_group_id)
  parameters                     = var.parameters
  port                           = local.resolved_port
  preferred_cache_cluster_azs    = var.preferred_cache_cluster_azs
  security_group_description     = var.security_group_description
  security_group_ids             = var.security_group_ids
  security_group_name            = coalesce(var.security_group_name, local.replication_group_id)
  security_group_names           = var.security_group_names
  security_group_rules           = var.security_group_rules
  security_group_tags            = var.security_group_tags
  security_group_use_name_prefix = var.security_group_use_name_prefix
  snapshot_arns                  = var.snapshot_arns
  snapshot_name                  = var.snapshot_name
  snapshot_retention_limit       = var.snapshot_retention_limit
  snapshot_window                = var.snapshot_window
  subnet_group_description       = var.subnet_group_description
  subnet_group_name              = coalesce(var.subnet_group_name, local.replication_group_id)
  subnet_ids                     = var.subnet_ids
  timeouts                       = var.timeouts
  user_group_ids                 = var.user_group_ids
  vpc_id                         = var.vpc_id

  create_parameter_group = var.create_parameter_group
  create_security_group  = var.create_security_group
  create_subnet_group    = var.create_subnet_group

  tags = module.this.tags
}
