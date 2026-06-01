################################################################
# Security Hub
#
# Thin wrapper around the upstream `cloudposse/security-hub/aws`
# module, pinned to a specific version. Naming and tagging are
# derived from `context.tf` via `module.this` and forwarded to
# the upstream module so resources composed by sibling screening
# modules stay consistent.
#
# Reference:
# https://registry.terraform.io/modules/cloudposse/security-hub/aws/latest

################################################################

module "security_hub" {
  source  = "cloudposse/security-hub/aws"
  version = "0.12.2"

  enabled_standards        = var.enabled_standards
  enable_default_standards = var.enable_default_standards

  finding_aggregator_enabled      = var.finding_aggregator_enabled
  finding_aggregator_linking_mode = var.finding_aggregator_linking_mode
  finding_aggregator_regions      = var.finding_aggregator_regions

  # SNS topic ownership stays with the alerting module — we just
  # point the upstream CloudWatch event rule at an existing topic.
  create_sns_topic                          = false
  imported_findings_notification_arn        = var.findings_notification_arn
  cloudwatch_event_rule_pattern_detail_type = var.cloudwatch_event_rule_pattern_detail_type

  # Cloud Posse modules still expect namespace/stage style context keys.
  # Our in-repo tags context uses service/environment naming, so map them.
  context = merge(module.this.context, {
    namespace = module.this.service
    stage     = module.this.environment
    tenant    = module.this.project
  })
}