locals {
  azs      = length(coalesce(var.availability_zones, [])) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 3)
  az_count = length(local.azs)

  # ─────────────────────────────────────────────────────────────
  # VPC CIDR prefix validation
  #
  # Extract the VPC prefix and validate cross-variable constraints.
  # ─────────────────────────────────────────────────────────────
  vpc_prefix_length = tonumber(split("/", var.vpc_cidr)[1])

  # ─────────────────────────────────────────────────────────────
  # Subnet CIDR allocation
  #
  # Uses cidrsubnets() to carve non-overlapping ranges from the
  # VPC CIDR.  The target subnet sizes are controlled by
  # var.firewall_subnet_prefix, etc.
  #
  # newbits = target_prefix - vpc_prefix
  # ─────────────────────────────────────────────────────────────
  firewall_newbits = var.firewall_subnet_prefix - local.vpc_prefix_length
  public_newbits   = var.public_subnet_prefix - local.vpc_prefix_length
  private_newbits  = var.private_subnet_prefix - local.vpc_prefix_length
  intra_newbits    = var.intra_subnet_prefix - local.vpc_prefix_length

  # Build a flat list of newbits, conditionally including only enabled subnet types.
  # cidrsubnets() only carves address space for subnet types that are actually created,
  # allowing minimal VPCs (e.g., intra-only from a /24 CIDR).
  auto_newbits = concat(
    var.create_firewall_subnets ? [for _ in range(local.az_count) : local.firewall_newbits] : [],
    var.create_public_subnets ? [for _ in range(local.az_count) : local.public_newbits] : [],
    var.create_private_subnets ? [for _ in range(local.az_count) : local.private_newbits] : [],
    var.create_intra_subnets ? [for _ in range(local.az_count) : local.intra_newbits] : [],
  )
  auto_subnets = length(local.auto_newbits) > 0 ? cidrsubnets(var.vpc_cidr, local.auto_newbits...) : []

  # Calculate slice boundaries dynamically based on which subnet types are enabled
  firewall_start = 0
  firewall_end   = var.create_firewall_subnets ? local.az_count : 0

  public_start = local.firewall_end
  public_end   = local.public_start + (var.create_public_subnets ? local.az_count : 0)

  private_start = local.public_end
  private_end   = local.private_start + (var.create_private_subnets ? local.az_count : 0)

  intra_start = local.private_end
  intra_end   = local.intra_start + (var.create_intra_subnets ? local.az_count : 0)

  auto_firewall_subnets = var.create_firewall_subnets ? slice(local.auto_subnets, local.firewall_start, local.firewall_end) : []
  auto_public_subnets   = var.create_public_subnets ? slice(local.auto_subnets, local.public_start, local.public_end) : []
  auto_private_subnets  = var.create_private_subnets ? slice(local.auto_subnets, local.private_start, local.private_end) : []
  auto_intra_subnets    = var.create_intra_subnets ? slice(local.auto_subnets, local.intra_start, local.intra_end) : []

  # Allow explicit overrides per tier
  firewall_subnets = length(var.firewall_subnets) > 0 ? var.firewall_subnets : local.auto_firewall_subnets
  public_subnets   = length(var.public_subnets) > 0 ? var.public_subnets : local.auto_public_subnets
  private_subnets  = length(var.private_subnets) > 0 ? var.private_subnets : local.auto_private_subnets
  intra_subnets    = length(var.intra_subnets) > 0 ? var.intra_subnets : local.auto_intra_subnets
}
