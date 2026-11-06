output "metric_stream_arn" {
  description = "ARN of the CloudWatch metric stream."
  value       = module.this.enabled ? module.metric_stream.cloudwatch_metric_stream : null
}

output "metric_stream_state" {
  description = "Current state of the CloudWatch metric stream."
  value       = module.this.enabled ? module.metric_stream.cloudwatch_metric_stream_state : null
}

output "metric_stream_name" {
  description = "Name of the CloudWatch metric stream."
  value       = module.this.enabled ? coalesce(var.stream_name, module.this.id) : null
}
