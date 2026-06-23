################################################################
# Network Firewall Module
#
# Screening wrapper around the
# `terraform-aws-modules/network-firewall/aws` upstream module
#
# Deploys an AWS Network Firewall into dedicated firewall
# subnets, typically passed in as an output from the VPC module.
#
# Enforces the platform's baseline security controls:
#
#   * Deletion protection enabled by default (opt-out requires explicit override)
#   * Subnet change protection enabled by default
#   * Logging opt-in (disabled by default to prevent log ingestion costs)
#   * All resources tagged via module.this
#   * Creation gated by module.this.enabled
#
# Naming and tagging are derived from context.tf via module.this.
################################################################

module "network_firewall" {
  source  = "terraform-aws-modules/network-firewall/aws"
  version = "2.1.0"

  create = module.this.enabled

  # ------------------------------------------------------------------
  # Firewall
  # ------------------------------------------------------------------
  name        = module.this.id
  description = var.description

  vpc_id         = var.vpc_id
  subnet_mapping = local.subnet_mapping

  delete_protection                 = var.delete_protection
  subnet_change_protection          = var.subnet_change_protection
  firewall_policy_change_protection = var.firewall_policy_change_protection
  enabled_analysis_types            = var.enabled_analysis_types
  encryption_configuration          = local.encryption_configuration

  # ------------------------------------------------------------------
  # Logging
  # ------------------------------------------------------------------
  create_logging_configuration             = local.create_logging
  logging_configuration_destination_config = local.create_logging ? local.logging_config : null

  # ------------------------------------------------------------------
  # Policy
  # Keep policy creation inline by default so module-managed rule groups
  # can be attached without introducing a second module boundary.
  #
  # For externally managed policies, set `create_policy = false` and pass
  # `firewall_policy_arn`. In that mode, the upstream module skips the
  # inline policy settings below and attaches the supplied policy ARN
  # directly to the firewall.
  # ------------------------------------------------------------------
  create_policy       = var.create_policy
  firewall_policy_arn = var.firewall_policy_arn

  policy_name                     = module.this.id
  policy_description              = coalesce(var.description, "Firewall policy for ${module.this.id}")
  policy_encryption_configuration = local.encryption_configuration
  policy_variables                = var.policy_variables
  policy_stateful_default_actions = var.policy_stateful_default_actions
  policy_stateful_engine_options  = var.policy_stateful_engine_options
  # `rule_groups` is the preferred path for stateful rule groups created
  # by this module. `policy_stateful_rule_group_reference` remains
  # available for attaching additional externally managed stateful groups
  # to the same inline policy.
  policy_stateful_rule_group_reference      = local.merged_stateful_rule_group_references
  policy_stateless_default_actions          = var.policy_stateless_default_actions
  policy_stateless_fragment_default_actions = var.policy_stateless_fragment_default_actions
  policy_stateless_rule_group_reference     = var.policy_stateless_rule_group_reference
  policy_stateless_custom_action            = var.policy_stateless_custom_action

  tags = module.this.tags
}

################################################################
# Rule Groups
#
# Creates rule groups via the upstream rule-group submodule
# and automatically wires them into the firewall policy.
################################################################

module "rule_group" {
  source  = "terraform-aws-modules/network-firewall/aws//modules/rule-group"
  version = "2.1.0"

  for_each = { for k, v in var.rule_groups : k => v if module.this.enabled }

  create = module.this.enabled

  name        = "${module.this.id}${module.this.delimiter}${replace(each.key, "_", module.this.delimiter)}"
  description = each.value.description
  type        = each.value.type
  capacity    = each.value.capacity
  rules       = each.value.rules
  rule_group  = each.value.rule_group

  encryption_configuration = local.encryption_configuration

  tags = module.this.tags
}

################################################################
# Managed CloudWatch Log Group for ALERT logs
#
# Optional convenience resource. When `create_alert_log_group`
# is true, the module creates and manages the log group
# lifecycle (retention, KMS encryption). Callers reference the
# log group name in their `logging` map.
################################################################

resource "aws_cloudwatch_log_group" "alert" {
  count = module.this.enabled && var.create_alert_log_group ? 1 : 0

  name              = "/aws/network-firewall/${module.this.id}"
  retention_in_days = var.alert_log_group_retention_in_days
  kms_key_id        = var.alert_log_group_kms_key_id

  tags = module.this.tags
}
