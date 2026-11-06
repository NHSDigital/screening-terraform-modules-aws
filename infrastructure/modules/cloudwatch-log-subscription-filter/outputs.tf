output "subscription_filter_name" {
  description = "Context-derived name of the CloudWatch Logs subscription filter."
  value       = module.this.enabled ? module.subscription_filter.cloudwatch_log_subscription_filter_name : null
}
