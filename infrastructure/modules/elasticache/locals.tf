locals {
  # ================================================================
  # Deployment mode
  # ================================================================
  create_replication_group = var.deployment_mode == "replication_group"
  create_cluster           = var.deployment_mode == "cluster"
  create_serverless_cache  = var.deployment_mode == "serverless"

  # ================================================================
  # Naming
  # ================================================================
  replication_group_id          = module.this.id
  cluster_id                    = module.this.id
  replication_group_description = "ElastiCache ${var.engine} for ${module.this.id}"
  final_snapshot_id             = "${module.this.id}-final-snapshot"

  # ================================================================
  # Engine helpers
  # ================================================================
  major_engine_version = split(".", var.engine_version)[0]

  # ElastiCache parameter group family — e.g. valkey8, redis7, memcached1.6
  parameter_family = var.engine == "memcached" ? "memcached${split(".", var.engine_version)[0]}.${split(".", var.engine_version)[1]}" : "${lower(var.engine)}${split(".", var.engine_version)[0]}"

  # Extract HH:MM from snapshot_window (format hh:mi-hh:mi) for the serverless
  # daily_snapshot_time argument which expects HH:MM format.
  serverless_snapshot_time = var.snapshot_window != null ? split("-", var.snapshot_window)[0] : null

  # ================================================================
  # CloudWatch log group names
  # ================================================================
  # Distinct names per log type. The upstream module uses these to create
  # separate log groups for slow-log and engine-log, avoiding the naming
  # collision that would occur if both types used the same path.
  cloudwatch_log_group_slow_log_name   = "/aws/elasticache/${module.this.id}/slow-log"
  cloudwatch_log_group_engine_log_name = "/aws/elasticache/${module.this.id}/engine-log"

  # Default log delivery configuration (used when var.log_delivery_configuration = null).
  # Lets the upstream module create log groups with distinct names per log type.
  default_log_delivery_configuration = {
    slow-log = {
      destination_type            = "cloudwatch-logs"
      log_format                  = "json"
      create_cloudwatch_log_group = true
      destination                 = local.cloudwatch_log_group_slow_log_name
    }
    engine-log = {
      destination_type            = "cloudwatch-logs"
      log_format                  = "json"
      create_cloudwatch_log_group = true
      destination                 = local.cloudwatch_log_group_engine_log_name
    }
  }
}
