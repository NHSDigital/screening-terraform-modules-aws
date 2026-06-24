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
}
