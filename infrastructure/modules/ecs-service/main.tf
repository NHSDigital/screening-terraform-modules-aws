module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 7.5.0"

  create = module.this.enabled
  name   = module.this.name
  tags   = module.this.tags

  alarms                             = var.alarms
  assign_public_ip                   = var.assign_public_ip
  autoscaling_max_capacity           = var.autoscaling_max_capacity
  autoscaling_min_capacity           = var.autoscaling_min_capacity
  autoscaling_policies               = var.autoscaling_policies
  autoscaling_scheduled_actions      = var.autoscaling_scheduled_actions
  autoscaling_suspended_state        = var.autoscaling_suspended_state
  availability_zone_rebalancing      = var.availability_zone_rebalancing
  capacity_provider_strategy         = var.capacity_provider_strategy
  cluster_arn                        = var.cluster_arn
  container_definitions              = var.container_definitions
  cpu                                = var.cpu
  create_iam_role                    = var.create_iam_role
  create_infrastructure_iam_role     = var.create_infrastructure_iam_role
  create_security_group              = var.create_security_group
  create_service                     = var.create_service
  create_task_definition             = var.create_task_definition
  create_task_exec_iam_role          = var.create_task_exec_iam_role
  create_task_exec_policy            = var.create_task_exec_policy
  create_tasks_iam_role              = var.create_tasks_iam_role
  deployment_circuit_breaker         = var.deployment_circuit_breaker
  deployment_configuration           = var.deployment_configuration
  deployment_controller              = var.deployment_controller
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  desired_count                      = var.desired_count
}
