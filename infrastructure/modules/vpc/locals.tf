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

  # Build a flat list of newbits: [firewall x N, public x N, private x N, intra x N]
  # cidrsubnets() guarantees non-overlapping, correctly-aligned CIDRs.
  auto_newbits = concat(
    [for _ in range(local.az_count) : local.firewall_newbits],
    [for _ in range(local.az_count) : local.public_newbits],
    [for _ in range(local.az_count) : local.private_newbits],
    [for _ in range(local.az_count) : local.intra_newbits],
  )
  auto_subnets = cidrsubnets(var.vpc_cidr, local.auto_newbits...)

  auto_firewall_subnets = slice(local.auto_subnets, 0, local.az_count)
  auto_public_subnets   = slice(local.auto_subnets, local.az_count, 2 * local.az_count)
  auto_private_subnets  = slice(local.auto_subnets, 2 * local.az_count, 3 * local.az_count)
  auto_intra_subnets    = slice(local.auto_subnets, 3 * local.az_count, 4 * local.az_count)

  # Allow explicit overrides per tier
  firewall_subnets = length(var.firewall_subnets) > 0 ? var.firewall_subnets : local.auto_firewall_subnets
  public_subnets   = length(var.public_subnets) > 0 ? var.public_subnets : local.auto_public_subnets
  private_subnets  = length(var.private_subnets) > 0 ? var.private_subnets : local.auto_private_subnets
  intra_subnets    = length(var.intra_subnets) > 0 ? var.intra_subnets : local.auto_intra_subnets
}
