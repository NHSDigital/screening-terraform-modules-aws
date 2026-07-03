output "cloudwatch_log_metric_filter_id" {
  description = "ID of the CloudWatch log metric filter."
  value       = module.this.enabled ? module.log_metric_filter.cloudwatch_log_metric_filter_id : null
}

output "metric_name" {
  description = "Name of the metric emitted by this filter (for downstream alarm reference)."
  value       = module.this.enabled ? var.metric_transformation_name : null
}

output "metric_namespace" {
  description = "CloudWatch namespace where the metric is emitted."
  value       = module.this.enabled ? local.metric_namespace : null
}
