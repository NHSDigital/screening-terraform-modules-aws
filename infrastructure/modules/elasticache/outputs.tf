output "deployment_mode" {
  description = "Active deployment mode: replication_group, cluster, or serverless."
  value       = var.deployment_mode
}

# ================================================================
# Replication group (deployment_mode = "replication_group")
# ================================================================

output "replication_group_id" {
  description = "ID of the ElastiCache replication group."
  value       = module.this.enabled && local.create_replication_group ? module.elasticache.replication_group_id : null
}

output "replication_group_arn" {
  description = "ARN of the ElastiCache replication group."
  value       = module.this.enabled && local.create_replication_group ? module.elasticache.replication_group_arn : null
}

output "primary_endpoint_address" {
  description = "Primary (writer) endpoint for the replication group."
  value       = module.this.enabled && local.create_replication_group ? module.elasticache.replication_group_primary_endpoint_address : null
}

output "reader_endpoint_address" {
  description = "Reader endpoint (load-balanced across replicas) for the replication group."
  value       = module.this.enabled && local.create_replication_group ? module.elasticache.replication_group_reader_endpoint_address : null
}

output "configuration_endpoint_address" {
  description = "Configuration endpoint for cluster-mode replication groups (connects to all shards)."
  value       = module.this.enabled && local.create_replication_group ? module.elasticache.replication_group_configuration_endpoint_address : null
}

output "member_clusters" {
  description = "List of member node IDs in the replication group."
  value       = module.this.enabled && local.create_replication_group ? module.elasticache.replication_group_member_clusters : []
}

output "port" {
  description = "Port on which the ElastiCache resource listens."
  value       = module.this.enabled && local.create_replication_group ? module.elasticache.replication_group_port : var.port
}

# ================================================================
# Cluster (deployment_mode = "cluster")
# ================================================================

output "cluster_arn" {
  description = "ARN of the standalone ElastiCache cluster."
  value       = module.this.enabled && local.create_cluster ? module.elasticache.cluster_arn : null
}

output "cluster_address" {
  description = "DNS name of the cache cluster (Memcached) or primary endpoint."
  value       = module.this.enabled && local.create_cluster ? module.elasticache.cluster_address : null
}

output "cluster_configuration_endpoint" {
  description = "Configuration endpoint for Memcached clusters (auto-discovery)."
  value       = module.this.enabled && local.create_cluster ? module.elasticache.cluster_configuration_endpoint : null
}

# ================================================================
# Serverless (deployment_mode = "serverless")
# ================================================================

output "serverless_arn" {
  description = "ARN of the serverless cache."
  value       = module.this.enabled && local.create_serverless_cache ? module.elasticache_serverless.serverless_cache_arn : null
}

output "serverless_endpoint" {
  description = "Connection endpoint (address and port) for the serverless cache."
  value       = module.this.enabled && local.create_serverless_cache ? module.elasticache_serverless.serverless_cache_endpoint : null
}

output "serverless_reader_endpoint" {
  description = "Reader endpoint for the serverless cache."
  value       = module.this.enabled && local.create_serverless_cache ? module.elasticache_serverless.serverless_cache_reader_endpoint : null
}

# ================================================================
# Networking
# ================================================================

output "security_group_id" {
  description = <<-EOT
    First security group ID associated with the cache.
    This is security_group_ids[0] (caller-managed).
  EOT
  value       = module.this.enabled && length(var.security_group_ids) > 0 ? var.security_group_ids[0] : null
}

# ================================================================
# Logging
# ================================================================
# The upstream module creates log groups with these names in the default scenario.
# When a custom config is provided, the actual log group creation depends on the
# create_cloudwatch_log_group setting provided by the caller.

output "cloudwatch_log_group_slow_log_name" {
  description = "Name of the CloudWatch log group for ElastiCache slow logs."
  value       = module.this.enabled && !local.create_serverless_cache ? local.cloudwatch_log_group_slow_log_name : null
}

output "cloudwatch_log_group_engine_log_name" {
  description = "Name of the CloudWatch log group for ElastiCache engine logs."
  value       = module.this.enabled && !local.create_serverless_cache ? local.cloudwatch_log_group_engine_log_name : null
}

# ================================================================
# Maintenance & backup
# ================================================================

output "snapshot_window" {
  description = "Time window for automated snapshots (UTC)."
  value       = var.snapshot_window
}

output "maintenance_window" {
  description = "Maintenance window (UTC)."
  value       = var.maintenance_window
}
