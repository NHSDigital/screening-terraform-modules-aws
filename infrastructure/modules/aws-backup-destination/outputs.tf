output "vault_arn" {
  description = "ARN of the destination backup vault."
  value       = aws_backup_vault.vault.arn
}

output "vault_name" {
  description = "Name of the destination backup vault."
  value       = aws_backup_vault.vault.name
}

output "copy_recovery_point_role_arn" {
  description = "ARN of role to assume from source account lambda (set ASSUME_ROLE_ARN to this). Only present if enabled."
  value       = try(aws_iam_role.copy_recovery_point[0].arn, null)
  depends_on  = [aws_iam_role.copy_recovery_point]
}
