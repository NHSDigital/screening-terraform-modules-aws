output "sns_topic_arn" {
  description = "ARN of the SNS topic."
  value       = module.sns.topic_arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic."
  value       = module.sns.topic_name
}

output "subscriptions" {
  description = "Map of SNS subscriptions created and their attributes."
  value       = module.sns.subscriptions
}
