locals {
  # Derive the cluster name from context when no explicit override is provided.
  cluster_name = var.cluster_name != null ? var.cluster_name : module.this.id

  # Container Insights setting, enabled by default for observability
  cluster_settings = var.enable_container_insights ? [
    {
      name  = "containerInsights"
      value = "enabled"
    }
  ] : []

  # ECS Exec log_configuration block (nested within execute_command_configuration)
  # Maps to: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster#log_configuration
  log_configuration = var.enable_execute_command ? {
    cloud_watch_encryption_enabled = var.cloud_watch_encryption_enabled
    cloud_watch_log_group_name     = var.cloudwatch_log_group_name
    s3_bucket_encryption_enabled   = var.s3_bucket_encryption_enabled
    s3_bucket_name                 = var.s3_bucket_name
    s3_kms_key_id                  = var.s3_kms_key_id
    s3_key_prefix                  = var.s3_key_prefix
  } : null

  # ECS Exec execute_command_configuration block
  # Maps to: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster#execute_command_configuration
  execute_command_configuration = var.enable_execute_command ? {
    kms_key_id        = var.execute_command_kms_key_id
    log_configuration = local.log_configuration
    logging           = "OVERRIDE"
  } : null

  # Cluster-level configuration block for upstream module
  cluster_configuration = var.enable_execute_command ? {
    execute_command_configuration = local.execute_command_configuration
  } : null
}
