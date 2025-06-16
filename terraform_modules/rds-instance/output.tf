output "rds_instance_arn" {
  value       = aws_db_instance.rds.arn
  description = "The ARN of the RDS instance"
}

output "rds_instance_endpoint" {
  value       = aws_db_instance.rds.endpoint
  description = "The endpoint of the RDS instance"
}

output "rds_name" {
  value = aws_db_instance.rds.identifier
}
