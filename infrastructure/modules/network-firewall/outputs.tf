################################################################
# Firewall
################################################################

output "firewall_arn" {
  description = "The ARN of the Network Firewall."
  value       = try(module.network_firewall.arn, null)
}

output "firewall_id" {
  description = "The ARN that identifies the firewall (same as arn)."
  value       = try(module.network_firewall.id, null)
}

output "firewall_status" {
  description = "Nested list of information about the current status of the firewall."
  value       = try(module.network_firewall.status, null)
}

output "firewall_update_token" {
  description = "A string token used when updating the firewall."
  value       = try(module.network_firewall.update_token, null)
}

################################################################
# Logging
################################################################

output "logging_configuration_id" {
  description = "The ARN of the associated firewall logging configuration."
  value       = try(module.network_firewall.logging_configuration_id, null)
}

output "alert_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group for ALERT logs."
  value       = try(aws_cloudwatch_log_group.alert[0].arn, null)
}

output "alert_log_group_name" {
  description = "The name of the CloudWatch Log Group for ALERT logs."
  value       = try(aws_cloudwatch_log_group.alert[0].name, null)
}

################################################################
# Policy
################################################################

output "policy_arn" {
  description = "The ARN of the firewall policy."
  value       = try(module.network_firewall.policy_arn, null)
}

output "policy_id" {
  description = "The ARN that identifies the firewall policy."
  value       = try(module.network_firewall.policy_id, null)
}

output "policy_update_token" {
  description = "A string token used when updating the firewall policy."
  value       = try(module.network_firewall.policy_update_token, null)
}
