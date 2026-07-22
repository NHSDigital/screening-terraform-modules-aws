################################################################
# Outputs
#
# Expose all VPC endpoints created by the upstream module.
# For advanced use cases (e.g., extracting specific endpoint IDs),
# callers can access full endpoint attributes via this output.
################################################################

output "endpoints" {
  description = "Map of VPC endpoints created, keyed by logical name. Contains all endpoint attributes (id, arn, network_interface_ids, subnet_ids, security_groups, etc.)."
  value       = module.vpc_endpoints.endpoints
}

output "security_groups" {
  description = "Map of security groups associated with endpoints. Only populated if upstream module created security groups (not applicable to this wrapper, which sets create_security_group=false)."
  value       = try(module.vpc_endpoints.security_groups, {})
}
