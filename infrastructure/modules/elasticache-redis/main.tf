# ----------------------------------------------------------------------------
# Elasticache Redis / Valkey replication group
#
# Wraps terraform-aws-modules/elasticache/aws v1.11.0.
#
# Fixed controls (not exposed as variables):
#   - at_rest_encryption_enabled  = true   (encryption at rest is mandatory)
#   - transit_encryption_enabled  = true   (encryption in transit is mandatory)
#   - create_cluster              = false  (always replication group, not standalone)
#   - create_replication_group    = true
#   - create_security_group       = false  (SGs managed externally via security-group module)
# ----------------------------------------------------------------------------

locals {
  replication_group_id = substr(coalesce(var.replication_group_id, module.this.id), 0, 40)

  engine_version_major = try(regex("^\\d+", var.engine_version), null)

  parameter_group_family = coalesce(
    var.parameter_group_family,
    local.engine_version_major != null ? "${var.engine}${local.engine_version_major}" : null
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

  create                   = module.this.enabled
  create_cluster           = false
  create_replication_group = true

  # Engine
  engine               = var.engine
  engine_version       = var.engine_version
  replication_group_id = local.replication_group_id
  description          = coalesce(var.description, "${local.replication_group_id} ${title(var.engine)} replication group")

  # Instance sizing
  node_type = var.node_type
  port      = var.port

  # Encryption (fixed controls)
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  transit_encryption_mode    = var.transit_encryption_mode
  auth_token                 = var.auth_token
  kms_key_arn                = var.kms_key_arn

  # Cluster topology
  cluster_mode            = var.cluster_mode
  num_cache_clusters      = var.num_cache_clusters
  num_node_groups         = var.num_node_groups
  replicas_per_node_group = var.replicas_per_node_group

  # Availability
  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled
  apply_immediately          = var.apply_immediately
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  maintenance_window         = var.maintenance_window

  # Networking (SGs managed externally)
  create_security_group = false
  security_group_ids    = var.security_group_ids

  # Subnet group (managed by this module)
  create_subnet_group      = true
  subnet_group_name        = coalesce(var.subnet_group_name, local.replication_group_id)
  subnet_group_description = var.subnet_group_description
  subnet_ids               = var.subnet_ids

  # Parameter group
  create_parameter_group      = var.create_parameter_group
  parameter_group_family      = coalesce(local.parameter_group_family, "")
  parameter_group_name        = coalesce(var.parameter_group_name, local.replication_group_id)
  parameter_group_description = var.parameter_group_description
  parameters                  = var.parameters

  # Logging
  log_delivery_configuration = local.log_delivery_configuration
  notification_topic_arn     = var.notification_topic_arn

  # Snapshots
  snapshot_retention_limit  = var.snapshot_retention_limit
  snapshot_window           = var.snapshot_window
  final_snapshot_identifier = var.final_snapshot_identifier

  tags = module.this.tags
}
