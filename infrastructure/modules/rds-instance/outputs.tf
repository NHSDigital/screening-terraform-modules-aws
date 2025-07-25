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
  value = aws_db_instance.rds.identifier
}

output "bss_user_secret_arn" {
  value = aws_secretsmanager_secret.password["bss_user"].arn
}

