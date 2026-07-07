output "user_pool_id" {
  description = "ID of the Cognito user pool."
  value       = module.cognito.id
}

output "user_pool_arn" {
  description = "ARN of the Cognito user pool."
  value       = module.cognito.arn
}

output "user_pool_name" {
  description = "Name of the Cognito user pool."
  value       = module.cognito.name
}

output "user_pool_endpoint" {
  description = "Cognito user pool endpoint."
  value       = module.cognito.endpoint
}

output "user_pool_domain_prefix" {
  description = "Configured Cognito domain value."
  value       = local.domain_name
}

output "user_pool_hosted_ui_url" {
  description = "Hosted UI URL for the Cognito domain when a default domain prefix is configured."
  value       = local.domain_name != null ? "https://${local.domain_name}.auth.${var.aws_region}.amazoncognito.com" : null
}

output "client_ids" {
  description = "IDs of any Cognito user pool clients created by this module."
  value       = module.cognito.client_ids
}

output "client_ids_map" {
  description = "Map of Cognito client names to client IDs."
  value       = module.cognito.client_ids_map
}

output "app_client_ids" {
  description = "Map of shared-resources app client names to client IDs."
  value       = module.cognito.client_ids_map
}

output "client_secrets" {
  description = "Secrets of any Cognito user pool clients created by this module."
  value       = module.cognito.client_secrets
  sensitive   = true
}

output "client_secrets_map" {
  description = "Map of Cognito client names to client secrets."
  value       = module.cognito.client_secrets_map
  sensitive   = true
}

output "app_client_secrets" {
  description = "Map of shared-resources app client names to client secrets."
  value       = module.cognito.client_secrets_map
  sensitive   = true
}

output "secrets_manager_random_password_arn" {
  description = "Deprecated compatibility output from the bespoke BS-Select bootstrap-user flow. This wrapper does not create a bootstrap user secret."
  value       = null
}
