################################################################
# Input validation
#
# Validates cross-variable constraints that cannot be expressed
# through individual variable validation blocks:
#
#   * storage_type 'io1' or 'io2' requires iops to be set
#   * manage_master_user_password = true requires master_user_secret_kms_key_id
#   * module-managed log groups require cloudwatch_log_group_kms_key_id (when create_cloudwatch_log_group = true)
################################################################

resource "terraform_data" "validations" {
  count = module.this.enabled ? 1 : 0

  lifecycle {
    precondition {
      condition     = !(contains(["io1", "io2"], coalesce(var.storage_type, "")) && var.iops == null)
      error_message = "iops must be set when storage_type is 'io1' or 'io2'."
    }

    precondition {
      condition     = !var.manage_master_user_password || var.master_user_secret_kms_key_id != null
      error_message = "master_user_secret_kms_key_id must be set when manage_master_user_password is true. AWS-managed keys are not acceptable per platform policy."
    }

    precondition {
      condition     = !(var.create_cloudwatch_log_group && length(var.enabled_cloudwatch_logs_exports) > 0 && var.cloudwatch_log_group_kms_key_id == null)
      error_message = "cloudwatch_log_group_kms_key_id must be set when the module creates CloudWatch log groups (create_cloudwatch_log_group = true). AWS-managed keys are not acceptable per platform policy."
    }
  }
}
