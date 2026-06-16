output "user_pool_id" {
  description = "ID of the Cognito user pool"
  value = aws_cognito_user_pool.cognito_user_pool.id
}

output "secrets_manager_random_passsword_arn" {
  description = "ARN of the Secrets Manager secret containing generated password"
  value = aws_secretsmanager_secret.password.arn
}

output "user_pool_domain_prefix" {
  description = "Domain prefix configured for the Cognito user pool domain"
  value = aws_cognito_user_pool_domain.main.domain
}
