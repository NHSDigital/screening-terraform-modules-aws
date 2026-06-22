locals {
  # Build the subnet_mapping from the firewall subnet IDs provided
  # by the VPC module.
  subnet_mapping = { for idx, subnet_id in var.firewall_subnet_ids :
    "subnet-${idx}" => {
      subnet_id       = subnet_id
      ip_address_type = "IPV4"
    }
  }

  # KMS encryption configuration for the firewall and policy.

  encryption_configuration = var.kms_key_arn != null ? {
    key_id = var.kms_key_arn
    type   = "CUSTOMER_KMS"
  } : null

  # ----------------------------------------------------------------
  # Logging configuration
  #
  # Build the upstream module's logging_configuration_destination_config
  # from the flexible `var.logging` map, filtering out disabled entries.
  # ----------------------------------------------------------------
  logging_config = [
    for k, v in var.logging : {
      log_destination      = v.log_destination
      log_destination_type = v.log_destination_type
      log_type             = v.log_type
    } if v.enabled
  ]

  create_logging = var.create_logging_configuration

  # ----------------------------------------------------------------
  # Rule group references
  #
  # Merge module-created rule groups (from var.rule_groups) with
  # any externally supplied references (from
  # var.policy_stateful_rule_group_reference).
  # ----------------------------------------------------------------
  # TODO: below looks very complicated – can it be simplified with fewer merges and conditionals?
  module_stateful_rule_group_references = {
    for k, v in var.rule_groups : k => merge(
      { resource_arn = module.rule_group[k].arn },
      v.priority != null ? { priority = v.priority } : {}
    ) if v.type == "STATEFUL"
  }

  merged_stateful_rule_group_references = length(local.module_stateful_rule_group_references) > 0 || var.policy_stateful_rule_group_reference != null ? merge(
    local.module_stateful_rule_group_references,
    coalesce(var.policy_stateful_rule_group_reference, {})
  ) : null
}
