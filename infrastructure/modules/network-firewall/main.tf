################################################################
# Network Firewall Module
#
# Screening wrapper around the
# `terraform-aws-modules/network-firewall/aws` upstream module
#
# Deploys an AWS Network Firewall into the dedicated firewall
# subnets created by the VPC module

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
  # ------------------------------------------------------------------
  create_policy    = var.create_policy
  firewall_policy_arn = var.firewall_policy_arn

  policy_name                            = module.this.id
  policy_description                     = coalesce(var.description, "Firewall policy for ${module.this.id}")
  policy_encryption_configuration        = local.encryption_configuration
  policy_variables                       = var.policy_variables
  policy_stateful_default_actions        = var.policy_stateful_default_actions
  policy_stateful_engine_options         = var.policy_stateful_engine_options
  policy_stateful_rule_group_reference   = var.policy_stateful_rule_group_reference
  policy_stateless_default_actions       = var.policy_stateless_default_actions
  policy_stateless_fragment_default_actions = var.policy_stateless_fragment_default_actions
  policy_stateless_rule_group_reference  = var.policy_stateless_rule_group_reference
  policy_stateless_custom_action         = var.policy_stateless_custom_action

  tags = module.this.tags
}

################################################################
# CloudWatch Log Group for ALERT logs
#
# Created as a standalone resource so that the log group
# lifecycle (retention, encryption) is managed by this module
# rather than being implicit within the firewall.
################################################################

resource "aws_cloudwatch_log_group" "alert" {
  count = module.this.enabled && var.create_alert_log ? 1 : 0

  name              = "/aws/network-firewall/${module.this.id}"
  retention_in_days = var.alert_log_retention_in_days
  kms_key_id        = var.alert_log_kms_key_id

  tags = module.this.tags
}
