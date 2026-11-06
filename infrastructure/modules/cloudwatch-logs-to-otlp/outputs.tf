output "firehose_arn" {
  description = "ARN of the CloudWatch Logs Firehose delivery stream."
  value       = module.firehose.delivery_stream_arn
}

output "forwarder_lambda_arn" {
  description = "ARN of the OTLP forwarder Lambda."
  value       = module.forwarder.lambda_arn
}

output "failure_bucket_arn" {
  description = "ARN of the private S3 bucket used by Firehose for retained and failed records."
  value       = module.failure_bucket.bucket_arn
}

output "subscription_dlq_arn" {
  description = "ARN of the SQS queue used for EventBridge subscription-controller failures."
  value       = module.subscription_dlq.queue_arn
}

output "existing_subscription_filter_names" {
  description = "Map of discovered log-group names to their subscription-filter names."
  value       = { for log_group, filter in module.existing_group_subscriptions : log_group => filter.subscription_filter_name }
}

output "future_subscription_event_rule_arn" {
  description = "ARN of the EventBridge rule used for future log groups, or null when future enrolment is disabled."
  value       = module.this.enabled && var.subscribe_future_log_groups ? module.future_group_subscriptions[0].event_rule_arn : null
}
