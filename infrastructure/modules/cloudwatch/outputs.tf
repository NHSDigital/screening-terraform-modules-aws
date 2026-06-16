output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group, if created."
  value       = module.log_group.cloudwatch_log_group_name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group, if created."
  value       = module.log_group.cloudwatch_log_group_arn
}

output "cloudwatch_log_stream_name" {
  description = "Name of the CloudWatch log stream, if created."
  value       = module.log_stream.cloudwatch_log_stream_name
}

output "cloudwatch_log_stream_arn" {
  description = "ARN of the CloudWatch log stream, if created."
  value       = module.log_stream.cloudwatch_log_stream_arn
}

output "cloudwatch_log_metric_filter_id" {
  description = "The name of the CloudWatch log metric filter, if created."
  value       = module.log_metric_filter.cloudwatch_log_metric_filter_id
}

output "cloudwatch_metric_alarm_id" {
  description = "The ID of the CloudWatch metric alarm, if created."
  value       = module.metric_alarm.cloudwatch_metric_alarm_id
}

output "cloudwatch_metric_alarm_arn" {
  description = "The ARN of the CloudWatch metric alarm, if created."
  value       = module.metric_alarm.cloudwatch_metric_alarm_arn
}

output "cloudwatch_metric_alarm_ids" {
  description = "Map of CloudWatch metric alarm IDs created by the multiple-dimensions submodule, if configured."
  value       = module.metric_alarms_by_multiple_dimensions.cloudwatch_metric_alarm_ids
}

output "cloudwatch_metric_alarm_arns" {
  description = "Map of CloudWatch metric alarm ARNs created by the multiple-dimensions submodule, if configured."
  value       = module.metric_alarms_by_multiple_dimensions.cloudwatch_metric_alarm_arns
}