output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group, if created."
  value       = var.create_log_group ? module.log_group.cloudwatch_log_group_name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group, if created."
  value       = var.create_log_group ? module.log_group.cloudwatch_log_group_arn : null
}

output "cloudwatch_log_stream_name" {
  description = "Name of the CloudWatch log stream, if created."
  value       = var.create_log_stream ? module.log_stream.cloudwatch_log_stream_name : null
}

output "cloudwatch_log_stream_arn" {
  description = "ARN of the CloudWatch log stream, if created."
  value       = var.create_log_stream ? module.log_stream.cloudwatch_log_stream_arn : null
}
