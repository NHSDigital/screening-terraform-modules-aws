output "policy_arns" {
  description = "Map of policy key -> arn for every IAM policy created by this module."
  value       = { for k, m in module.policies : k => m.arn }
}

output "policy_names" {
  description = "Map of policy key -> name for every IAM policy created by this module."
  value       = { for k, m in module.policies : k => m.name }
}

output "role_arns" {
  description = "Map of role key -> arn for every IAM role created by this module."
  value       = { for k, m in module.roles : k => m.arn }
}

output "role_names" {
  description = "Map of role key -> name for every IAM role created by this module."
  value       = { for k, m in module.roles : k => m.name }
}
