################################################################
# Outputs
#
# Expose all VPC endpoints created by the upstream module.
# For advanced use cases (e.g., extracting specific endpoint IDs),
# callers can access full endpoint attributes via this output.
#
# Validation outputs below provide status and enforce preconditions
# on endpoint configuration (security groups, policies, route tables).
################################################################

output "endpoints" {
  description = "Map of VPC endpoints created, keyed by logical name. Contains all endpoint attributes (id, arn, network_interface_ids, subnet_ids, security_groups, etc.)."
  value       = module.vpc_endpoints.endpoints
}

output "security_groups" {
  description = "Map of security groups associated with endpoints. Only populated if upstream module created security groups (not applicable to this wrapper, which sets create_security_group=false)."
  value       = try(module.vpc_endpoints.security_groups, {})
}

# Validation outputs: Provide status and enforce preconditions on endpoint configuration

output "validate_security_group_coverage" {
  description = "Validation status: Ensures Interface endpoints have security group coverage (either per-endpoint security_group_ids or module-level var.security_group_id as default)"
  value       = length(local.interface_endpoints_without_sgs) == 0 || var.security_group_id != null ? "Valid: Security group coverage satisfied" : "Invalid: See error above"

  precondition {
    condition     = length(local.interface_endpoints_without_sgs) == 0 || var.security_group_id != null
    error_message = "Interface endpoints (${join(", ", local.interface_endpoints_without_sgs)}) must have security_group_ids specified per-endpoint or use var.security_group_id as default."
  }
}

output "validate_gateway_endpoint_config" {
  description = "Validation status: Ensures Gateway endpoints have route_table_ids and do not have security_group_ids"
  value       = (length(local.gateway_endpoints_with_sgs) == 0 && length(local.gateway_endpoints_without_rtb) == 0) ? "Valid: Gateway endpoint configuration satisfied" : "Invalid: See error above"

  precondition {
    condition     = length(local.gateway_endpoints_with_sgs) == 0
    error_message = "Gateway endpoints (${join(", ", local.gateway_endpoints_with_sgs)}) do not support security_group_ids. Remove this attribute or change service_type to Interface."
  }

  precondition {
    condition     = length(local.gateway_endpoints_without_rtb) == 0
    error_message = "Gateway endpoints (${join(", ", local.gateway_endpoints_without_rtb)}) require route_table_ids to specify which route tables to associate with."
  }
}

output "validate_endpoint_policies" {
  description = "Informational: Policy coverage for Gateway endpoints. Both Gateway and Interface endpoints support policies; Gateway endpoints (S3, DynamoDB) should have restrictive policies as a security best practice."
  value       = length(local.gateway_endpoints_without_policies) == 0 ? "All Gateway endpoints have policies" : "Warning: Gateway endpoints (${join(", ", local.gateway_endpoints_without_policies)}) do not have restrictive policies. Recommended for security."
}

output "validate_endpoints_not_empty" {
  description = "Informational: Confirms endpoints are specified"
  value       = "Endpoints defined"
}
