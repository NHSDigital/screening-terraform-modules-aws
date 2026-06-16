output "bss_user_secret_arn" {
  description = "ARN of the Secrets Manager secret containing bss_user credentials."
  value       = aws_secretsmanager_secret.password["bss_user"].arn
}
