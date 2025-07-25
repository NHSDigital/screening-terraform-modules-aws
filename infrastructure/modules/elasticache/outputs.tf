output "redis_configuration_endpoint_address" {
  value = aws_elasticache_replication_group.elasticache_replication_group.configuration_endpoint_address
}

output "redis_configuration_endpoint_port" {
  value = aws_elasticache_replication_group.elasticache_replication_group.port
}

output "redis_security_group_id" {
  value = aws_security_group.cache_sg.id
}
