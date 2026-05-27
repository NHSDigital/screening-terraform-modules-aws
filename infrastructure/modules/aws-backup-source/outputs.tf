output "backup_role_arn" {
  value       = aws_iam_role.backup.arn
  description = "ARN of the of the backup role"
}

output "backup_vault_arn" {
  value       = aws_backup_vault.main.arn
  description = "ARN of the of the vault"
}

output "backup_vault_name" {
  value       = aws_backup_vault.main.name
  description = "Name of the of the vault"
}

output "restore_validation_lambda_arn" {
  value       = var.backup_plan_config_rds.enable && var.restore_validation_enable ? aws_lambda_function.restore_validation[0].arn : null
  description = "ARN of the restore validation Lambda function"
}

output "restore_validation_lambda_name" {
  value       = var.backup_plan_config_rds.enable && var.restore_validation_enable ? aws_lambda_function.restore_validation[0].function_name : null
  description = "Name of the restore validation Lambda function"
}

output "restore_validation_eventbridge_rule_name" {
  value       = var.backup_plan_config_rds.enable && var.restore_validation_enable ? aws_cloudwatch_event_rule.restore_testing_complete[0].name : null
  description = "Name of the EventBridge rule that triggers restore validation"
}
