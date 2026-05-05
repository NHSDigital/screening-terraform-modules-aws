locals {
  resource_name_prefix                             = var.name_prefix != null ? var.name_prefix : "${data.aws_region.current.region}-${data.aws_caller_identity.current.account_id}-backup"
  selection_tag_value_rds_null_checked             = (var.backup_plan_config_rds.selection_tag_value == null) ? "True" : var.backup_plan_config_rds.selection_tag_value
  selection_tags_rds_null_checked                  = (var.backup_plan_config_rds.selection_tags == null) ? [{ "key" : var.backup_plan_config_rds.selection_tag, "value" : local.selection_tag_value_rds_null_checked }] : var.backup_plan_config_rds.selection_tags
  framework_arn_list = flatten(concat(
    var.backup_plan_config_rds.enable ? [aws_backup_framework.rds[0].arn] : []
  ))
  #aurora_overrides    = var.backup_plan_config_aurora.restore_testing_overrides == null ? null : var.backup_plan_config_aurora.restore_testing_overrides
  rds_overrides       = var.backup_plan_config_rds.restore_testing_overrides == null ? null : var.backup_plan_config_rds.restore_testing_overrides
  terraform_role_arns = length(var.terraform_role_arns) > 0 ? var.terraform_role_arns : [var.terraform_role_arn]
}
