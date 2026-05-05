resource "aws_backup_plan" "rds" {
  count = var.backup_plan_config_rds.enable ? 1 : 0
  name  = "${var.name_prefix}-rds-plan"

  dynamic "rule" {
    for_each = var.backup_plan_config_rds.rules
    content {
      recovery_point_tags = {
        backup_rule_name = rule.value.name
      }
      rule_name         = rule.value.name
      target_vault_name = aws_backup_vault.main.name
      schedule          = rule.value.schedule
      completion_window = rule.value.completion_window
      lifecycle {
        delete_after       = rule.value.lifecycle.delete_after != null ? rule.value.lifecycle.delete_after : null
        cold_storage_after = rule.value.lifecycle.cold_storage_after != null ? rule.value.lifecycle.cold_storage_after : null
      }
      dynamic "copy_action" {
        for_each = rule.value.copy_action != null ? rule.value.copy_action : {}
        content {
          lifecycle {
            delete_after = copy_action.value
          }
          destination_vault_arn = aws_backup_vault.intermediary_vault[0].arn
        }
      }
    }
  }
}

resource "aws_backup_selection" "rds" {
  count        = var.backup_plan_config_rds.enable ? 1 : 0
  iam_role_arn = aws_iam_role.backup.arn
  name         = "${var.name_prefix}-rds-selection"
  plan_id      = aws_backup_plan.rds[0].id

  selection_tag {
    key   = var.backup_plan_config_rds.selection_tag
    type  = "STRINGEQUALS"
    value = (var.backup_plan_config_rds.selection_tag_value == null) ? "True" : var.backup_plan_config_rds.selection_tag_value
  }
  condition {
    dynamic "string_equals" {
      for_each = local.selection_tags_rds_null_checked
      content {
        key   = (try(string_equals.value.key, null) == null) ? null : "aws:ResourceTag/${string_equals.value.key}"
        value = try(string_equals.value.value, null)
      }
    }
  }
}
