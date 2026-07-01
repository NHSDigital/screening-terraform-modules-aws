output "cloudwatch_metric_alarm_id" {
  description = "Alarm ID from single metric alarm (if created)."
  value       = var.metric_alarm != null ? module.metric_alarm.cloudwatch_metric_alarm_id : null
}

output "cloudwatch_metric_alarm_arn" {
  description = "Alarm ARN from single metric alarm (if created)."
  value       = var.metric_alarm != null ? module.metric_alarm.cloudwatch_metric_alarm_arn : null
}

output "cloudwatch_metric_alarms_by_multiple_dimensions_ids" {
  description = "Map of alarm IDs keyed by dimension combination (if created)."
  value       = var.metric_alarms_by_multiple_dimensions != null ? module.metric_alarms_by_multiple_dimensions.cloudwatch_metric_alarm_ids : {}
}

output "cloudwatch_metric_alarms_by_multiple_dimensions_arns" {
  description = "Map of alarm ARNs keyed by dimension combination (if created)."
  value       = var.metric_alarms_by_multiple_dimensions != null ? module.metric_alarms_by_multiple_dimensions.cloudwatch_metric_alarm_arns : {}
}
