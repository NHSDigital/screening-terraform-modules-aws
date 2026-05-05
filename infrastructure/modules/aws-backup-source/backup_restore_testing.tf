resource "aws_backup_restore_testing_plan" "backup_restore_testing_plan" {
  name                = var.name_prefix != null ? "${replace(var.name_prefix, "-", "_")}_backup_restore_testing_plan" : "backup_restore_testing_plan"
  schedule_expression = var.restore_testing_plan_scheduled_expression
  start_window_hours  = var.restore_testing_plan_start_window
  recovery_point_selection {
    algorithm             = var.restore_testing_plan_algorithm
    include_vaults        = [aws_backup_vault.main.arn]
    recovery_point_types  = var.restore_testing_plan_recovery_point_types
    selection_window_days = var.restore_testing_plan_selection_window_days
  }
}

resource "aws_backup_restore_testing_selection" "backup_restore_testing_selection_rds" {
  count                     = var.backup_plan_config_rds.enable ? 1 : 0
  name                      = "backup_restore_testing_selection_rds"
  restore_testing_plan_name = aws_backup_restore_testing_plan.backup_restore_testing_plan.name
  iam_role_arn              = aws_iam_role.backup.arn
  validation_window_hours   = var.backup_plan_config_rds.validation_window_hours   # number of hours to leave the restored RDS instance available for custom validation checks
  protected_resource_type   = "RDS"
  protected_resource_conditions {
    string_equals {
      key   = "aws:ResourceTag/${var.backup_plan_config_rds.selection_tag}"
      value = "True"
    }
  }
  restore_metadata_overrides = local.rds_overrides
}
