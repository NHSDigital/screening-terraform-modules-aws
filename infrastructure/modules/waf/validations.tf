################################################################
# Input validation
#
# Validates cross-variable constraints that cannot be expressed
# through individual variable validation blocks:
#
#   * Rule priority uniqueness across all rule lists
#   * Rule name uniqueness within the web ACL
#   * CloudWatch metric name format for all visibility configs
################################################################

locals {
  all_rule_priorities = concat(
    [for r in var.byte_match_statement_rules : r.priority],
    [for r in var.geo_allowlist_statement_rules : r.priority],
    [for r in var.geo_match_statement_rules : r.priority],
    [for r in var.ip_set_reference_statement_rules : r.priority],
    [for r in var.managed_rule_group_statement_rules : r.priority],
    [for r in var.nested_statement_rules : r.priority],
    [for r in var.rate_based_statement_rules : r.priority],
    [for r in var.regex_match_statement_rules : r.priority],
    [for r in var.regex_pattern_set_reference_statement_rules : r.priority],
    [for r in var.rule_group_reference_statement_rules : r.priority],
    [for r in var.size_constraint_statement_rules : r.priority],
    [for r in var.sqli_match_statement_rules : r.priority],
    [for r in var.xss_match_statement_rules : r.priority],
  )

  all_rule_names = concat(
    [for r in var.byte_match_statement_rules : r.name],
    [for r in var.geo_allowlist_statement_rules : r.name],
    [for r in var.geo_match_statement_rules : r.name],
    [for r in var.ip_set_reference_statement_rules : r.name],
    [for r in var.managed_rule_group_statement_rules : r.name],
    [for r in var.nested_statement_rules : r.name],
    [for r in var.rate_based_statement_rules : r.name],
    [for r in var.regex_match_statement_rules : r.name],
    [for r in var.regex_pattern_set_reference_statement_rules : r.name],
    [for r in var.rule_group_reference_statement_rules : r.name],
    [for r in var.size_constraint_statement_rules : r.name],
    [for r in var.sqli_match_statement_rules : r.name],
    [for r in var.xss_match_statement_rules : r.name],
  )

  # Explicit metric names from per-rule visibility_config blocks, plus the web ACL-level metric name.
  all_metric_names = concat(
    [for r in var.byte_match_statement_rules : r.visibility_config.metric_name if r.visibility_config != null],
    [for r in var.geo_allowlist_statement_rules : r.visibility_config.metric_name if r.visibility_config != null],
    [for r in var.geo_match_statement_rules : r.visibility_config.metric_name if r.visibility_config != null],
    [for r in var.ip_set_reference_statement_rules : r.visibility_config.metric_name if r.visibility_config != null],
    [for r in var.managed_rule_group_statement_rules : r.visibility_config.metric_name if r.visibility_config != null],
    [for r in var.nested_statement_rules : r.visibility_config.metric_name if r.visibility_config != null],
    [for r in var.rate_based_statement_rules : r.visibility_config.metric_name if r.visibility_config != null],
    [for r in var.regex_match_statement_rules : r.visibility_config.metric_name if r.visibility_config != null],
    [for r in var.regex_pattern_set_reference_statement_rules : r.visibility_config.metric_name if r.visibility_config != null],
    [for r in var.rule_group_reference_statement_rules : r.visibility_config.metric_name if r.visibility_config != null],
    [for r in var.size_constraint_statement_rules : r.visibility_config.metric_name if r.visibility_config != null],
    [for r in var.sqli_match_statement_rules : r.visibility_config.metric_name if r.visibility_config != null],
    [for r in var.xss_match_statement_rules : r.visibility_config.metric_name if r.visibility_config != null],
    [local.visibility_config.metric_name],
  )
}

resource "terraform_data" "validations" {
  lifecycle {
    precondition {
      condition     = length(local.all_rule_priorities) == length(toset(local.all_rule_priorities))
      error_message = "All WAF rule priorities must be unique across all rule lists. Check for duplicate priority values."
    }

    precondition {
      condition     = length(local.all_rule_names) == length(toset(local.all_rule_names))
      error_message = "All WAF rule names must be unique within the web ACL. Check for duplicate rule names."
    }

    precondition {
      condition     = alltrue([for m in local.all_metric_names : can(regex("^[-a-zA-Z0-9_.]+$", m))])
      error_message = "All visibility_config.metric_name values must contain only alphanumeric characters, underscores (_), hyphens (-), or periods (.)."
    }
  }
}
