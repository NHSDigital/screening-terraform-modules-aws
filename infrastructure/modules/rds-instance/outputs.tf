output "rds_instance_arn" {
  value       = aws_db_instance.rds.arn
  description = "The ARN of the RDS instance"
}

output "rds_instance_endpoint" {
  value       = aws_db_instance.rds.endpoint
  description = "The endpoint of the RDS instance including port"
}

output "rds_instance_address" {
  value       = aws_db_instance.rds.address
  description = "Endpoint of the instance excluding port"
}

output "rds_name" {
  description = "Identifier name of the RDS instance."
  value       = aws_db_instance.rds.identifier
}

output "rds_instance_id" {
  value       = aws_db_instance.rds.id
  description = "The ID of the RDS instance"
}

output "rds_sg_id" {
  value       = aws_security_group.rds.id
  description = "The security group ID for the RDS instance"
}
