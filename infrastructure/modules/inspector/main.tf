################################################################
# Inspector
#
# Thin wrapper around the upstream `cloudposse/inspector/aws`
# module, pinned to a specific version. Naming and tagging are
# derived from `context.tf` via `module.this` and passed through
# to the upstream module so resources composed by sibling
# screening modules stay consistent.
#
# Reference:
# https://registry.terraform.io/modules/cloudposse/inspector/aws/latest
################################################################

module "inspector" {
  source  = "cloudposse/inspector/aws"
  version = "0.4.0"

  enabled_rules = var.enabled_rules

  assessment_duration           = var.assessment_duration
  schedule_expression           = var.schedule_expression
  event_rule_description        = var.event_rule_description
  create_iam_role               = var.create_iam_role
  iam_role_arn                  = var.iam_role_arn
  assessment_event_subscription = var.assessment_event_subscription

  context = module.this.context
}
