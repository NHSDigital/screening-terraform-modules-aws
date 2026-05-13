output "account_id" {
  description = "The AWS account ID that Security Hub has been enabled in."
  value       = try(aws_securityhub_account.this[0].id, null)
}

output "account_arn" {
  description = "The ARN of the Security Hub hub resource for this account."
  value       = try(aws_securityhub_account.this[0].arn, null)
}

output "enabled_standards_subscriptions" {
  description = "Map of subscribed Security Hub standards keyed by the input identifier, with the resulting subscription ARN as the value."
  value       = { for k, v in aws_securityhub_standards_subscription.this : k => v.id }
}

output "finding_aggregator_arn" {
  description = "ARN of the Security Hub finding aggregator, if created."
  value       = try(aws_securityhub_finding_aggregator.this[0].arn, null)
}

output "cloudwatch_event_rule_arn" {
  description = "ARN of the CloudWatch (EventBridge) rule forwarding Security Hub imported findings, if created."
  value       = try(aws_cloudwatch_event_rule.imported_findings[0].arn, null)
}
