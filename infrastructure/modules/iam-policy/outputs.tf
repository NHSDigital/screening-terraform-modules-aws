output "iam_policy_arn" {
  description = "The ARN assigned by AWS to this policy"
  value       = module.iam_policy.arn
}

output "iam_policy_id" {
  description = "The policy's ID"
  value       = module.iam_policy.id
}

output "iam_policy_name" {
  description = "The name of the policy"
  value       = module.iam_policy.name
}

output "iam_policy" {
  description = "The policy document"
  value       = module.iam_policy.policy
}
