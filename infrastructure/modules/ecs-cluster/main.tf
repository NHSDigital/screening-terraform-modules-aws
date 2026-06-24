################################################################
# ECS cluster
#
# Thin NHS wrapper around the community ECS cluster module that
# enforces the screening platform's baseline controls:
#
#   * Creation is gated by module.this.enabled
#   * Naming and tagging are enforced via context.tf
#   * CloudWatch Container Insights enabled by default
#   * ECS Exec logging uses an explicit CloudWatch Log Group
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

  # The CloudWatch Log Group is created only when ECS Exec is enabled.
  # Consider moving the CloudWatch Log Group creation to a separate module
  # so that it can be created independently of the ECS cluster.
  create_cloudwatch_log_group            = var.enable_execute_command
  cloudwatch_log_group_name              = local.cloudwatch_log_group_name
  cloudwatch_log_group_kms_key_id        = var.cloudwatch_log_group_kms_key_id
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_class             = var.cloudwatch_log_group_class

  cluster_capacity_providers         = var.cluster_capacity_providers
  default_capacity_provider_strategy = var.default_capacity_provider_strategy
  service_connect_defaults           = var.service_connect_defaults

  # Keep the module focused on the cluster itself; callers should
  # manage IAM/security group resources separately in dedicated modules.
  create_security_group            = false
  create_infrastructure_iam_role   = false
  create_node_iam_instance_profile = false
  create_task_exec_iam_role        = false
  create_task_exec_policy          = false

  tags = module.this.tags
}
