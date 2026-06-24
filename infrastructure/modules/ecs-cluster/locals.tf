locals {
  # Derive the cluster name from context when no explicit override is provided.
  cluster_name = var.cluster_name != null ? var.cluster_name : module.this.id

  cloudwatch_log_group_name = var.cloudwatch_log_group_name != null ? var.cloudwatch_log_group_name : "/aws/ecs/${local.cluster_name}/execute-command"

  cluster_settings = var.enable_container_insights ? [
    {
      name  = "containerInsights"
      value = "enabled"
    }
  ] : []

  cluster_configuration = var.enable_execute_command ? {
    execute_command_configuration = {
      kms_key_id = var.execute_command_kms_key_id
      logging    = "OVERRIDE"
      log_configuration = {
        cloud_watch_encryption_enabled = var.cloudwatch_log_group_kms_key_id != null
        cloud_watch_log_group_name     = local.cloudwatch_log_group_name
      }
    }
  } : null
}
