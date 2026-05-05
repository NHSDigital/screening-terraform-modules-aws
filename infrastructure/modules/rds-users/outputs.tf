output "bss_user_secret_arn" {
  value = aws_secretsmanager_secret.password["bss_user"].arn
}
