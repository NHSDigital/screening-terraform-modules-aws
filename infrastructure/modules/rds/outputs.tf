# Instance connection details

output "instance_address" {
  description = "Hostname of the RDS instance (without port)"
  value       = module.rds.db_instance_address
}

output "instance_port" {
  description = "Port on which the RDS instance accepts connections"
  value       = module.rds.db_instance_port
}

output "instance_endpoint" {
  description = "Connection endpoint for the RDS instance in host:port format"
  value       = module.rds.db_instance_endpoint
}

output "instance_id" {
  description = "Identifier of the RDS instance"
  value       = module.rds.db_instance_identifier
}

output "instance_arn" {
  description = "ARN of the RDS instance"
  value       = module.rds.db_instance_arn
}

output "instance_resource_id" {
  description = "The RDS resource ID (used for IAM authentication and tagging)"
  value       = module.rds.db_instance_resource_id
}

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret for the master user password. Only populated when manage_master_user_password is true"
  value       = module.rds.db_instance_master_user_secret_arn
}

# Security group

output "rds_security_group" {
  description = "The security group created for the RDS instance. Null when vpc_security_group_ids was provided by the caller"
  value       = local.create_security_group ? aws_security_group.this[0] : null
}

output "security_group_id" {
  description = "ID of the RDS security group. Null when vpc_security_group_ids was provided by the caller"
  value       = local.create_security_group ? aws_security_group.this[0].id : null
}

# Subnet group

output "rds_subnet_group" {
  description = "The DB subnet group used by the RDS instance, with id and arn attributes"
  value = {
    id  = module.rds.db_subnet_group_id
    arn = module.rds.db_subnet_group_arn
  }
}

output "db_subnet_group_id" {
  description = "Name/ID of the DB subnet group"
  value       = module.rds.db_subnet_group_id
}

# Parameter and option groups

output "db_parameter_group_id" {
  description = "ID of the DB parameter group"
  value       = module.rds.db_parameter_group_id
}

output "db_option_group_id" {
  description = "ID of the DB option group"
  value       = module.rds.db_option_group_id
}

# Monitoring

output "enhanced_monitoring_iam_role_arn" {
  description = "ARN of the Enhanced Monitoring IAM role. Empty when monitoring_interval is 0"
  value       = module.rds.enhanced_monitoring_iam_role_arn
}
