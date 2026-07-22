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

# Validation preconditions are now in outputs.tf
# This file contains locals and variable validations only.
