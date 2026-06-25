################################################################
# Web ACL
################################################################

variable "description" {
  description = "Friendly description of the WAF web ACL."
  type        = string
  default     = "Managed by Terraform"
}

variable "default_action" {
  description = "Default action for requests that do not match any rule. Valid values are allow or block."
  type        = string
  default     = "allow"

  validation {
    condition     = contains(["allow", "block"], var.default_action)
    error_message = "default_action must be either allow or block."
  }
}

variable "scope" {
  description = "Whether the web ACL is regional or for CloudFront."
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["CLOUDFRONT", "REGIONAL"], var.scope)
    error_message = "scope must be one of CLOUDFRONT or REGIONAL."
  }
}

variable "visibility_config" {
  description = "Visibility configuration for the web ACL. Leave null to use the module default metric name and sampling settings."
  type = object({
    cloudwatch_metrics_enabled = bool
    metric_name                = string
    sampled_requests_enabled   = bool
  })
  default = null
}

variable "association_resource_arns" {
  description = "List of resource ARNs to associate with this web ACL, such as an ALB, API Gateway stage, or AppSync resource."
  type        = list(string)
  default     = []
}

variable "token_domains" {
  description = "Optional list of token domains accepted by AWS WAF for cross-domain token usage."
  type        = list(string)
  default     = null
}

################################################################
# Logging
################################################################

variable "log_destination_configs" {
  description = "Destination ARNs for WAF logging. Create log groups, Firehose streams, or S3 buckets outside this module and pass their ARNs here."
  type        = list(string)
  default     = []
}

variable "logging_filter" {
  description = "Optional WAF logging filter configuration passed directly to the upstream module."
  type = object({
    default_behavior = string
    filter = list(object({
      behavior    = string
      requirement = string
      condition = list(object({
        action_condition = optional(object({
          action = string
        }), null)
        label_name_condition = optional(object({
          label_name = string
        }), null)
      }))
    }))
  })
  default = null
}

variable "redacted_fields" {
  description = "Optional log redaction settings passed directly to the upstream module."
  type = map(object({
    method        = optional(bool, false)
    uri_path      = optional(bool, false)
    query_string  = optional(bool, false)
    single_header = optional(list(string), null)
  }))
  default = {}
}

################################################################
# Custom responses
################################################################

variable "custom_response_body" {
  description = "Custom response bodies that can be referenced by block actions."
  type = map(object({
    content      = string
    content_type = string
  }))
  default = {}
}

variable "default_block_response" {
  description = "HTTP status code to return when default_action is block."
  type        = string
  default     = null
}

variable "default_block_custom_response_body_key" {
  description = "Custom response body key to use when default_action is block."
  type        = string
  default     = null
}

################################################################
# Rule inputs
################################################################

variable "byte_match_statement_rules" {
  description = "Byte match rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type        = list(any)
  default     = []
}

variable "geo_allowlist_statement_rules" {
  description = "Geo allowlist rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type        = list(any)
  default     = []
}

variable "geo_match_statement_rules" {
  description = "Geo match rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type        = list(any)
  default     = []
}

variable "ip_set_reference_statement_rules" {
  description = "IP set reference rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type        = list(any)
  default     = []
}

variable "managed_rule_group_statement_rules" {
  description = "Managed rule group rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type        = list(any)
  default     = []
}

variable "nested_statement_rules" {
  description = "Nested statement rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type        = list(any)
  default     = []
}

variable "rate_based_statement_rules" {
  description = "Rate-based rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type        = list(any)
  default     = []
}

variable "regex_match_statement_rules" {
  description = "Regex match rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type        = list(any)
  default     = []
}

variable "regex_pattern_set_reference_statement_rules" {
  description = "Regex pattern set reference rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type        = list(any)
  default     = []
}

variable "rule_group_reference_statement_rules" {
  description = "Rule group reference rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type        = list(any)
  default     = []
}

variable "size_constraint_statement_rules" {
  description = "Size constraint rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type        = list(any)
  default     = []
}

variable "sqli_match_statement_rules" {
  description = "SQL injection match rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type        = list(any)
  default     = []
}

variable "xss_match_statement_rules" {
  description = "Cross-site scripting match rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type        = list(any)
  default     = []
}