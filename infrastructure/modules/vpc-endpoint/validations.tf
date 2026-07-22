################################################################
# Validations (output preconditions)
#
# Enforce security and configuration requirements across endpoints.
################################################################

locals {
  # Extract interface endpoints that don't have security_group_ids specified
  interface_endpoints_without_sgs = [
    for k, v in var.endpoints :
    k if try(v.service_type, "Interface") == "Interface" && try(v.security_group_ids, null) == null
  ]

  # Check if any Gateway endpoints mistakenly have security_group_ids
  gateway_endpoints_with_sgs = [
    for k, v in var.endpoints :
    k if try(v.service_type, "Interface") == "Gateway" && try(v.security_group_ids, null) != null
  ]

  # Gateway endpoints without policies (security best practice)
  # Both Gateway and Interface endpoints support policies.
  # Gateway endpoints (S3, DynamoDB) especially should have restrictive policies.
  gateway_endpoints_without_policies = [
    for k, v in var.endpoints :
    k if try(v.service_type, "Interface") == "Gateway" && try(v.policy, null) == null
  ]

  # Gateway endpoints without route_table_ids
  gateway_endpoints_without_rtb = [
    for k, v in var.endpoints :
    k if try(v.service_type, "Interface") == "Gateway" && try(v.route_table_ids, null) == null
  ]
}

# Validation output: Ensures Interface endpoints have security group coverage
output "validate_security_group_coverage" {
  value = null

  precondition {
    condition     = length(local.interface_endpoints_without_sgs) == 0 || var.security_group_id != null
    error_message = "Interface endpoints (${join(", ", local.interface_endpoints_without_sgs)}) must have security_group_ids specified per-endpoint or use var.security_group_id as default."
  }
}

# Validation output: Ensures Gateway endpoint configuration
output "validate_gateway_endpoint_config" {
  value = null

  precondition {
    condition     = length(local.gateway_endpoints_with_sgs) == 0
    error_message = "Gateway endpoints (${join(", ", local.gateway_endpoints_with_sgs)}) do not support security_group_ids. Remove this attribute or change service_type to Interface."
  }

  precondition {
    condition     = length(local.gateway_endpoints_without_rtb) == 0
    error_message = "Gateway endpoints (${join(", ", local.gateway_endpoints_without_rtb)}) require route_table_ids to specify which route tables to associate with."
  }
}

# Ensure at least one endpoint is specified
variable "endpoints_not_empty" {
  type        = any
  default     = null
  description = "Internal validation: endpoints must not be empty"

  validation {
    condition     = length(var.endpoints) > 0
    error_message = "At least one endpoint must be specified. If vpc-endpoint module is not needed, remove it from the configuration."
  }
}

# Note: Both Gateway and Interface endpoints support policies.
# Gateway endpoints (S3, DynamoDB) should use restrictive policies as a security best practice.
# Interface endpoints (SNS, SQS, Secrets Manager, etc.) can optionally use policies for fine-grained access control.
output "validate_endpoint_policies" {
  value       = length(local.gateway_endpoints_without_policies) == 0 ? "All Gateway endpoints have policies" : "Warning: Gateway endpoints (${join(", ", local.gateway_endpoints_without_policies)}) do not have restrictive policies. Recommended for security."
  description = "Informational output: Gateway endpoint policy coverage"
}

# Validation output: Indicates endpoints are specified
output "validate_endpoints_not_empty" {
  value       = "Endpoints defined"
  description = "Informational output: Confirms endpoints are specified"
}
