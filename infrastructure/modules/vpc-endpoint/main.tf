################################################################
# VPC Endpoints Wrapper Module
#
# Creates Interface and Gateway VPC endpoints with support for:
# - Optional per-endpoint policies
# - Per-endpoint subnet overrides
# - Security group assignment (caller-managed)
# - Custom tags per endpoint
################################################################

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "6.6.1"

  vpc_id = var.vpc_id

  # Default subnet placement: intra (no internet route, high isolation)
  # Can be overridden per-endpoint via subnet_ids in endpoints map
  subnet_ids = var.subnet_ids

  # Security groups are created/managed at the stack level (caller responsibility)
  # Per-endpoint security_group_ids override the default var.security_group_id
  create_security_group = false

  # Use merged endpoints map to apply default security_group_id where needed
  endpoints = local.endpoints_merged

  tags = module.this.tags
}
