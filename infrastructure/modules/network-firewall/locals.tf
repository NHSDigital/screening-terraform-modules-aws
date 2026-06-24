locals {
  # Build the subnet_mapping from the firewall subnet IDs provided,
  # typically as an output from the VPC module.
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
  # `rule_groups` is the authoring interface for rule groups this module
  # creates itself. Only STATEFUL groups are merged into the inline
  # firewall policy reference map.
  # ----------------------------------------------------------------
  module_stateful_rule_group_references = {
    for k, v in var.rule_groups : k => merge(
      { resource_arn = module.rule_group[k].arn },
      v.priority != null ? { priority = v.priority } : {}
    ) if v.type == "STATEFUL"
  }

  # Normalise a nullable caller input to an empty map so the later
  # `length(...)` and `merge(...)` expressions do not need to handle null.
  external_stateful_rule_group_references = var.policy_stateful_rule_group_reference != null ? var.policy_stateful_rule_group_reference : {}

  # The upstream policy interface expects a single map of stateful rule
  # group references. This local keeps module-managed and external rule
  # groups composable while still returning null when neither is present.
  merged_stateful_rule_group_references = length(local.module_stateful_rule_group_references) + length(local.external_stateful_rule_group_references) > 0 ? merge(
    local.module_stateful_rule_group_references,
    local.external_stateful_rule_group_references
  ) : null
}
