################################################################
# CloudWatch Logs subscription filter
#
# Thin NHS wrapper around the community subscription-filter
# submodule. Naming, tagging, and creation gating use module.this.
################################################################

module "subscription_filter" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-subscription-filter"
  version = "6.0.0"

  create = module.this.enabled

  name            = module.this.id
  log_group_name  = var.log_group_name
  destination_arn = var.destination_arn
  role_arn        = var.role_arn
  filter_pattern  = var.filter_pattern
  distribution    = var.distribution
}
