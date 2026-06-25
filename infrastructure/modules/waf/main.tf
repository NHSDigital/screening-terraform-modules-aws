################################################################
# WAF
#
# Thin NHS wrapper around `cloudposse/waf/aws` that keeps naming and
# tagging aligned with the shared `context.tf` pattern while leaving
# rules, rule groups, associations, and logging destinations to the
# consumer.
################################################################

module "waf" {
  source  = "cloudposse/waf/aws"
  version = "1.17.0"

  association_resource_arns                   = var.association_resource_arns
  byte_match_statement_rules                  = var.byte_match_statement_rules
  custom_response_body                        = var.custom_response_body
  default_action                              = var.default_action
  default_block_custom_response_body_key      = var.default_block_custom_response_body_key
  default_block_response                      = var.default_block_response
  description                                 = var.description
  geo_allowlist_statement_rules               = var.geo_allowlist_statement_rules
  geo_match_statement_rules                   = var.geo_match_statement_rules
  ip_set_reference_statement_rules            = var.ip_set_reference_statement_rules
  log_destination_configs                     = var.log_destination_configs
  logging_filter                              = var.logging_filter
  managed_rule_group_statement_rules          = var.managed_rule_group_statement_rules
  nested_statement_rules                      = var.nested_statement_rules
  rate_based_statement_rules                  = var.rate_based_statement_rules
  redacted_fields                             = var.redacted_fields
  regex_match_statement_rules                 = var.regex_match_statement_rules
  regex_pattern_set_reference_statement_rules = var.regex_pattern_set_reference_statement_rules
  rule_group_reference_statement_rules        = var.rule_group_reference_statement_rules
  scope                                       = var.scope
  size_constraint_statement_rules             = var.size_constraint_statement_rules
  sqli_match_statement_rules                  = var.sqli_match_statement_rules
  token_domains                               = var.token_domains
  visibility_config                           = local.visibility_config
  xss_match_statement_rules                   = var.xss_match_statement_rules

  context = local.cloudposse_context
}