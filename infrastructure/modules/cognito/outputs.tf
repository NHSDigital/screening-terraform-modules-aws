output "user_pool_id" {
  value = aws_cognito_user_pool.cognito_user_pool.id
}

output "secrets_manager_random_passsword_arn" {
  value = aws_secretsmanager_secret.password.arn
}

output "user_pool_domain_prefix" {
  value = aws_cognito_user_pool_domain.main.domain
}
