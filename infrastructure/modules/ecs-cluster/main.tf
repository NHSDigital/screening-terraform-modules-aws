################################################################
# ECS cluster
#
# Thin NHS wrapper around the community ECS cluster module that
# enforces the screening platform's baseline controls:
#
#   * Creation is gated by module.this.enabled
#   * Naming and tagging are enforced via context.tf
#   * CloudWatch Container Insights enabled by default
#   * ECS Exec logging supports two destination options (KMS encrypted):
#     - CloudWatch Logs: Log group created separately via cloudwatch-logs module
#     - S3: Bucket with encryption enabled (managed by caller)
#   * At least one log destination REQUIRED if ECS Exec enabled
#   * Cross-variable validation rules enforced in validations.tf
#
# Naming and tagging are derived from context.tf via module.this.
################################################################

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "7.5.0"

  create = module.this.enabled
  name   = local.cluster_name

  setting = local.cluster_settings

  configuration = local.cluster_configuration

  # CloudWatch Log Group is optional (if using CloudWatch for ECS Exec logs).
  # When provided, it MUST be pre-created via the cloudwatch-logs module.
  # Do not create it here; only reference the pre-created log group.
  # Encryption (kms_key_id) is mandatory for security compliance.
  # S3 logging is supported as an alternative. See validations.tf for constraints.
  create_cloudwatch_log_group = false

  cluster_capacity_providers         = var.cluster_capacity_providers
  default_capacity_provider_strategy = var.default_capacity_provider_strategy
  service_connect_defaults           = var.service_connect_defaults

  # Container Insights setting is configured in local.cluster_settings
  # based on var.enable_container_insights; no need to set it again here.

  # Keep the module focused on the cluster itself; callers should
  # manage IAM/security group resources separately in dedicated modules.
  create_security_group            = false
  create_infrastructure_iam_role   = false
  create_node_iam_instance_profile = false
  create_task_exec_iam_role        = false
  create_task_exec_policy          = false

  tags = module.this.tags
}
