# Replication group

output "replication_group_arn" {
  description = "ARN of the ElastiCache replication group"
  value       = module.elasticache.replication_group_arn
}

output "replication_group_id" {
  description = "ID of the ElastiCache replication group"
  value       = module.elasticache.replication_group_id
}

output "replication_group_configuration_endpoint_address" {
  description = "Configuration endpoint address (cluster mode enabled)"
  value       = module.elasticache.replication_group_configuration_endpoint_address
}

output "replication_group_primary_endpoint_address" {
  description = "Primary endpoint address (cluster mode disabled)"
  value       = module.elasticache.replication_group_primary_endpoint_address
}

output "replication_group_reader_endpoint_address" {
  description = "Reader endpoint address (cluster mode disabled)"
  value       = module.elasticache.replication_group_reader_endpoint_address
}

output "replication_group_port" {
  description = "Port of the replication group"
  value       = module.elasticache.replication_group_port
}

# Parameter group

output "parameter_group_id" {
  description = "Name of the ElastiCache parameter group"
  value       = module.elasticache.parameter_group_id
}

# Subnet group

output "subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = module.elasticache.subnet_group_name
}
