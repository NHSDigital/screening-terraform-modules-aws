output "policy_arns" {
  description = "Map of policy key -> ARN for every IAM policy created by this module."
  value       = { for k, p in aws_iam_policy.this : k => p.arn }
}

output "policy_names" {
  description = "Map of policy key -> name for every IAM policy created by this module."
  value       = { for k, p in aws_iam_policy.this : k => p.name }
}

output "role_arns" {
  description = "Map of role key -> ARN for every IAM role created by this module."
  value       = { for k, r in aws_iam_role.this : k => r.arn }
}

output "role_names" {
  description = "Map of role key -> name for every IAM role created by this module."
  value       = { for k, r in aws_iam_role.this : k => r.name }
}
