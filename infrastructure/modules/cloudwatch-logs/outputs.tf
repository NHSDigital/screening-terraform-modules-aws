output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group."
  value       = module.this.enabled ? module.log_group.cloudwatch_log_group_name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group."
  value       = module.this.enabled ? module.log_group.cloudwatch_log_group_arn : null
}

output "cloudwatch_log_stream_names" {
  description = "Map of CloudWatch log stream names, keyed by stream name."
  value = {
    for name, stream in module.log_stream :
    name => stream.cloudwatch_log_stream_name
  }
}

output "cloudwatch_log_stream_arns" {
  description = "Map of CloudWatch log stream ARNs, keyed by stream name."
  value = {
    for name, stream in module.log_stream :
    name => stream.cloudwatch_log_stream_arn
  }
}
