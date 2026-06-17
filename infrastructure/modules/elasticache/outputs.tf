output "redis_configuration_endpoint_address" {
  description = "Configuration endpoint address for the ElastiCache replication group."
  value       = aws_elasticache_replication_group.elasticache_replication_group.configuration_endpoint_address
}

output "redis_configuration_endpoint_port" {
  description = "Configuration endpoint port for the ElastiCache replication group."
  value       = aws_elasticache_replication_group.elasticache_replication_group.port
}

output "redis_security_group_id" {
  description = "Security group ID attached to the ElastiCache replication group."
  value       = aws_security_group.cache_sg.id
}
