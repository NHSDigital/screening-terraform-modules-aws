output "cloudwatch_log_group_arn" {
  description = "ARN of the first CloudWatch log group created by the upstream module."
  value       = module.elasticache.cloudwatch_log_group_arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the first CloudWatch log group created by the upstream module."
  value       = module.elasticache.cloudwatch_log_group_name
}

output "cloudwatch_log_groups" {
  description = "Map of CloudWatch log groups created for Redis log delivery."
  value       = module.elasticache.cloudwatch_log_groups
}

output "parameter_group_arn" {
  description = "ARN of the ElastiCache parameter group."
  value       = module.elasticache.parameter_group_arn
}

output "parameter_group_id" {
  description = "Name of the ElastiCache parameter group."
  value       = module.elasticache.parameter_group_id
}

output "replication_group_arn" {
  description = "ARN of the Redis replication group."
  value       = module.elasticache.replication_group_arn
}

output "replication_group_configuration_endpoint_address" {
  description = "Configuration endpoint address when cluster mode is enabled."
  value       = module.elasticache.replication_group_configuration_endpoint_address
}

output "replication_group_engine_version_actual" {
  description = "Actual running Redis engine version after AWS applies minor or patch updates."
  value       = module.elasticache.replication_group_engine_version_actual
}

output "replication_group_id" {
  description = "ID of the Redis replication group."
  value       = module.elasticache.replication_group_id
}

output "replication_group_member_clusters" {
  description = "Identifiers of the clusters that belong to the replication group."
  value       = module.elasticache.replication_group_member_clusters
}

output "replication_group_port" {
  description = "Port of the primary node in the replication group when cluster mode is disabled."
  value       = module.elasticache.replication_group_port
}

output "replication_group_primary_endpoint_address" {
  description = "Primary endpoint address when cluster mode is disabled."
  value       = module.elasticache.replication_group_primary_endpoint_address
}

output "replication_group_reader_endpoint_address" {
  description = "Reader endpoint address when cluster mode is disabled."
  value       = module.elasticache.replication_group_reader_endpoint_address
}

output "security_group_arn" {
  description = "ARN of the created security group."
  value       = module.elasticache.security_group_arn
}

output "security_group_id" {
  description = "ID of the created security group."
  value       = module.elasticache.security_group_id
}

output "subnet_group_name" {
  description = "Name of the ElastiCache subnet group."
  value       = module.elasticache.subnet_group_name
}

output "redis_configuration_endpoint_address" {
  description = "Compatibility alias for replication_group_configuration_endpoint_address."
  value       = module.elasticache.replication_group_configuration_endpoint_address
}

output "redis_configuration_endpoint_port" {
  description = "Compatibility alias for replication_group_port."
  value       = module.elasticache.replication_group_port
}

output "redis_security_group_id" {
  description = "Compatibility alias for security_group_id."
  value       = module.elasticache.security_group_id
}
