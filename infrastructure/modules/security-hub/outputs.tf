output "enabled_subscriptions" {
  description = "List of Security Hub standards subscriptions enabled by the upstream module."
  value       = module.security_hub.enabled_subscriptions
}

output "sns_topic" {
  description = "The SNS topic that the upstream module created (null when `create_sns_topic` is false, which is the default for this wrapper)."
  value       = module.security_hub.sns_topic
}

output "sns_topic_subscriptions" {
  description = "Any SNS topic subscriptions that the upstream module created."
  value       = module.security_hub.sns_topic_subscriptions
}
