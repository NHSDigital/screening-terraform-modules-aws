################################################################
# WAF wrapper inputs.
#
# This module now wraps `cloudposse/waf/aws` for the Web ACL itself,
# while preserving the previous BCSS-specific resources as optional
# legacy add-ons so downstream consumers can migrate without an
# immediate breaking change.
################################################################

variable "name_prefix" {
  description = "Legacy naming prefix used by the original BCSS WAF module. When not set, the module derives names from `context.tf` inputs."
  type        = string
  default     = null
}

variable "waf_name" {
  description = "Explicit name for the WAF web ACL. Defaults to `name_prefix`, then to the shared tags context id."
  type        = string
  default     = null
}

variable "description" {
  description = "Description for the WAF web ACL."
  type        = string
  default     = "Managed by Terraform"
}

variable "scope" {
  description = "Whether this web ACL is regional or for CloudFront."
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["CLOUDFRONT", "REGIONAL"], var.scope)
    error_message = "scope must be one of CLOUDFRONT or REGIONAL."
  }
}

variable "default_action" {
  description = "Default action applied by the web ACL when no rule matches. The legacy module allowed by default, so this wrapper preserves that default."
  type        = string
  default     = "allow"

  validation {
    condition     = contains(["allow", "block"], var.default_action)
    error_message = "default_action must be either allow or block."
  }
}

variable "visibility_config" {
  description = "Visibility configuration for the Web ACL. Leave null to use the module default metric derived from `name_prefix` or the shared context id."
  type = object({
    cloudwatch_metrics_enabled = bool
    metric_name                = string
    sampled_requests_enabled   = bool
  })
  default = null
}

variable "association_resource_arns" {
  description = "Resource ARNs to associate with the web ACL. Typical values are ALB, API Gateway stage, or AppSync ARNs."
  type        = list(string)
  default     = []
}

variable "managed_rule_group_statement_rules" {
  description = "Managed rule group statements passed through to the upstream Cloud Posse WAF module. Leave empty to use the Screening default managed ruleset."
  type        = list(any)
  default     = []
}

variable "geo_match_statement_rules" {
  description = "Optional geo match rules passed through to the upstream Cloud Posse WAF module."
  type        = list(any)
  default     = []
}

variable "ip_set_reference_statement_rules" {
  description = "Optional IP set reference rules passed through to the upstream Cloud Posse WAF module."
  type        = list(any)
  default     = []
}

variable "rate_based_statement_rules" {
  description = "Optional rate-based rules passed through to the upstream Cloud Posse WAF module."
  type        = list(any)
  default     = []
}

variable "rule_group_reference_statement_rules" {
  description = "Optional rule-group reference rules passed through to the upstream Cloud Posse WAF module. The module appends the legacy BCSS webservices rule group here when enabled."
  type        = list(any)
  default     = []
}

variable "log_destination_configs" {
  description = "Additional WAF logging destination ARNs to pass to the upstream module. The BCSS legacy log group ARN is appended automatically when that feature is enabled."
  type        = list(string)
  default     = []
}

variable "token_domains" {
  description = "Optional token domains passed through to the upstream Cloud Posse WAF module."
  type        = list(string)
  default     = null
}

################################################################
# BCSS legacy compatibility inputs
################################################################

variable "enable_legacy_bcss_mode" {
  description = "Whether to enable the BCSS-specific IP sets, webservices rule group, legacy log forwarding, and Shield alarming. Leave null to auto-enable when legacy naming variables are provided."
  type        = bool
  default     = null
}

variable "enable_legacy_geo_rule" {
  description = "Whether to retain the previous non-GB geo match count rule. Defaults to the same value as `enable_legacy_bcss_mode`."
  type        = bool
  default     = null
}

variable "exclude_ip_set_name" {
  description = "Legacy BCSS IP set name used for excluded source addresses. Kept for compatibility; this wrapper creates the IP set when addresses are provided."
  type        = string
  default     = null
}

variable "exclude_ip_set_addresses" {
  description = "Explicit addresses for the legacy excluded IP set. When omitted in legacy mode, the module falls back to the `waf-ip-set` secret."
  type        = list(string)
  default     = null
}

variable "web_services_ip_set_name" {
  description = "Legacy BCSS IP set name used for the webservices allowlist."
  type        = string
  default     = null
}

variable "webservices_ip_set_addresses" {
  description = "List of webservices allowlist IP addresses. When omitted in legacy mode, the module falls back to the `waf-bsis-ip` secret."
  type        = list(string)
  default     = null
}

variable "webservices_protected_paths" {
  description = "URI path fragments protected by the legacy BCSS webservices rule. Requests to these paths are blocked unless they originate from the webservices IP set."
  type        = list(string)
  default     = ["/bss/dashboardExtracts", "/bss/rawdatamigration"]
}

variable "legacy_webservices_rule_capacity" {
  description = "Capacity assigned to the legacy BCSS webservices rule group."
  type        = number
  default     = 100
}

variable "legacy_webservices_rule_priority" {
  description = "Priority used when attaching the legacy BCSS webservices rule group to the web ACL."
  type        = number
  default     = 80
}

variable "legacy_geo_rule_priority" {
  description = "Priority used for the legacy non-GB geo count rule."
  type        = number
  default     = 100
}

variable "waf_ips_secret_name" {
  description = "Optional override for the secret containing the legacy excluded IP set addresses."
  type        = string
  default     = null
}

variable "waf_ips_secret_key" {
  description = "JSON key inside `waf_ips_secret_name` containing the excluded IP addresses."
  type        = string
  default     = "ips"
}

variable "waf_bsis_ip_range_secret_name" {
  description = "Optional override for the secret containing the legacy webservices allowlist addresses."
  type        = string
  default     = null
}

variable "waf_bsis_ip_range_secret_key" {
  description = "JSON key inside `waf_bsis_ip_range_secret_name` containing the webservices allowlist addresses."
  type        = string
  default     = "bsis_ip"
}

variable "waf_log_group_name" {
  description = "CloudWatch log group name used for WAF logging. Must start with `aws-waf-logs-` for AWS WAF logging. Defaults to an `aws-waf-logs-` prefix derived from either `name_prefix` or the shared context id."
  type        = string
  default     = null
}

variable "create_waf_log_group" {
  description = "Whether to create a dedicated CloudWatch log group and wire it into WAF logging. Defaults to the same value as `enable_legacy_bcss_mode`."
  type        = bool
  default     = null
}

variable "waf_log_retention_in_days" {
  description = "Retention period for the WAF CloudWatch log group."
  type        = number
  default     = 365
}

variable "aws_account_id" {
  description = "AWS account id used by the legacy cross-account log subscription, Splunk subscription, and Shield alarming features."
  type        = string
  default     = null
}

variable "alert_sns_topic_name" {
  description = "SNS topic name used by the legacy Shield DDoS alarm. Defaults to `name_prefix`."
  type        = string
  default     = null
}

variable "enable_central_logging_subscription" {
  description = "Whether to create the legacy cross-account CloudWatch Logs subscription for the WAF log group. Defaults to the same value as `enable_legacy_bcss_mode`."
  type        = bool
  default     = null
}

variable "cloudwatch_cross_account_secret_name" {
  description = "Optional override for the secret used to resolve the central logging account id for the legacy cross-account log subscription."
  type        = string
  default     = null
}

variable "cloudwatch_cross_account_secret_key" {
  description = "JSON key inside `cloudwatch_cross_account_secret_name` used to read the destination account id."
  type        = string
  default     = "central-logging"
}

variable "enable_splunk_logging_subscription" {
  description = "Whether to create the legacy Splunk Firehose CloudWatch Logs subscription for the WAF log group. Defaults to the same value as `enable_legacy_bcss_mode`."
  type        = bool
  default     = null
}

variable "enable_shield_ddos_alarming" {
  description = "Whether to create the legacy Shield DDoS alarm and EventBridge forwarding resources. Defaults to the same value as `enable_legacy_bcss_mode`, but only in prod."
  type        = bool
  default     = null
}

variable "shield_event_bus_region" {
  description = "Region containing the target EventBridge bus used by the legacy Shield DDoS forwarding rule."
  type        = string
  default     = "eu-west-2"
}
