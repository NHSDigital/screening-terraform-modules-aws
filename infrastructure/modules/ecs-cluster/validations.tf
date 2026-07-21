################################################################
# Cross-variable validation constraints for ECS cluster.
#
# These preconditions enforce:
#   * When ECS Exec is enabled:
#     - At least one log destination (CloudWatch and/or S3) required
#     - Session encryption (execute_command_kms_key_id) always required
#   * If CloudWatch destination: cloud_watch_encryption_enabled must be true
#   * If S3 destination: s3_bucket_encryption_enabled must be true, s3_kms_key_id required
#   * Both CloudWatch and S3 can be enabled simultaneously for redundancy
################################################################

resource "terraform_data" "validations" {
  count = module.this.enabled ? 1 : 0

  lifecycle {
    precondition {
      condition     = !var.enable_execute_command || (var.execute_command_kms_key_id != null && var.execute_command_kms_key_id != "")
      error_message = "When enable_execute_command = true, execute_command_kms_key_id is REQUIRED. ECS Exec session data must be encrypted. Provide a KMS key ARN or ID for session encryption."
    }

    precondition {
      condition = !var.enable_execute_command || (
        (var.cloudwatch_log_group_name != null && var.cloudwatch_log_group_name != "") ||
        (var.s3_bucket_name != null && var.s3_bucket_name != "")
      )
      error_message = "When enable_execute_command = true, at least one log destination is REQUIRED: cloudwatch_log_group_name and/or s3_bucket_name. Both can be configured simultaneously for redundancy."
    }

    precondition {
      condition     = var.cloudwatch_log_group_name == null || var.cloud_watch_encryption_enabled == true
      error_message = "When cloudwatch_log_group_name is provided, cloud_watch_encryption_enabled must be true. CloudWatch log encryption is mandatory for ECS Exec sessions."
    }

    precondition {
      condition     = var.s3_bucket_name == null || var.s3_bucket_name == "" || var.s3_bucket_encryption_enabled == true
      error_message = "When s3_bucket_name is provided, s3_bucket_encryption_enabled must be set to true. S3 encryption is mandatory for ECS Exec session logs."
    }

    precondition {
      condition     = !var.s3_bucket_encryption_enabled || (var.s3_kms_key_id != null && var.s3_kms_key_id != "")
      error_message = "When s3_bucket_encryption_enabled = true, s3_kms_key_id is REQUIRED. Provide a KMS key ARN or ID for S3 encryption of ECS Exec session logs."
    }
  }
}
