output "secret_arn" {
  description = "The ARN of the secret"
  value       = module.secret.secret_arn
}

output "secret_id" {
  description = "The ID of the secret (same as the ARN)"
  value       = module.secret.secret_id
}

output "secret_name" {
  description = "The name of the secret"
  value       = module.secret.secret_name
}

output "secret_version_id" {
  description = "The unique identifier of the current version of the secret"
  value       = module.secret.secret_version_id
}
