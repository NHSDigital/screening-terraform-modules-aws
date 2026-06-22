module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 7.5.0"

  create = module.this.enabled
  name   = module.this.name
  tags   = module.this.tags

  alarms                        = var.alarms
  assign_public_ip              = var.assign_public_ip
  autoscaling_max_capacity      = var.autoscaling_max_capacity
  autoscaling_min_capacity      = var.autoscaling_min_capacity
  autoscaling_policies          = var.autoscaling_policies
  autoscaling_scheduled_actions = var.autoscaling_scheduled_actions
  autoscaling_suspended_state   = var.autoscaling_suspended_state
  availability_zone_rebalancing = var.availability_zone_rebalancing
}
