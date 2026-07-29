################################################################
# Input validation
#
# Validates cross-variable constraints that cannot be expressed
# through individual variable validation blocks:
#
#   * At least one subnet type must be enabled (create_* flag = true)
#   * Subnet prefix must be more specific than VPC CIDR (only when
#     auto-calculating that subnet type — if explicit subnets are
#     provided, the prefix is ignored)
#   * enable_network_firewall requires firewall subnets to be created
#   * single_nat_gateway requires private subnets to be created
#   * Explicit subnet CIDR lists must have correct length (equal to az_count)
#
################################################################

resource "terraform_data" "validations" {
  count = module.this.enabled ? 1 : 0

  lifecycle {
    precondition {
      condition = (
        var.create_firewall_subnets ||
        var.create_public_subnets ||
        var.create_private_subnets ||
        var.create_intra_subnets
      )
      error_message = "At least one subnet type must be created (set one or more of: create_firewall_subnets, create_public_subnets, create_private_subnets, create_intra_subnets to true)."
    }

    # Prefix validations: only apply when auto-calculating (explicit subnets are empty)
    precondition {
      condition = (
        !var.create_firewall_subnets ||
        length(var.firewall_subnets) > 0 ||
        var.firewall_subnet_prefix > local.vpc_prefix_length
      )
      error_message = "firewall_subnet_prefix (/${var.firewall_subnet_prefix}) must be more specific than VPC CIDR (/${local.vpc_prefix_length}) when auto-calculating firewall subnets (firewall_subnets is empty). When using explicit firewall_subnets, the prefix is ignored."
    }

    precondition {
      condition = (
        !var.create_public_subnets ||
        length(var.public_subnets) > 0 ||
        var.public_subnet_prefix > local.vpc_prefix_length
      )
      error_message = "public_subnet_prefix (/${var.public_subnet_prefix}) must be more specific than VPC CIDR (/${local.vpc_prefix_length}) when auto-calculating public subnets (public_subnets is empty). When using explicit public_subnets, the prefix is ignored."
    }

    precondition {
      condition = (
        !var.create_private_subnets ||
        length(var.private_subnets) > 0 ||
        var.private_subnet_prefix > local.vpc_prefix_length
      )
      error_message = "private_subnet_prefix (/${var.private_subnet_prefix}) must be more specific than VPC CIDR (/${local.vpc_prefix_length}) when auto-calculating private subnets (private_subnets is empty). When using explicit private_subnets, the prefix is ignored."
    }

    precondition {
      condition = (
        !var.create_intra_subnets ||
        length(var.intra_subnets) > 0 ||
        var.intra_subnet_prefix > local.vpc_prefix_length
      )
      error_message = "intra_subnet_prefix (/${var.intra_subnet_prefix}) must be more specific than VPC CIDR (/${local.vpc_prefix_length}) when auto-calculating intra subnets (intra_subnets is empty). When using explicit intra_subnets, the prefix is ignored."
    }

    precondition {
      condition     = !var.enable_network_firewall || var.create_firewall_subnets
      error_message = "enable_network_firewall = true requires create_firewall_subnets = true."
    }

    precondition {
      condition     = !var.single_nat_gateway || var.create_private_subnets
      error_message = "single_nat_gateway = true requires create_private_subnets = true (NAT gateway must route traffic to private subnets)."
    }

    precondition {
      condition     = !var.enable_nat_gateway || var.create_private_subnets
      error_message = "enable_nat_gateway = true requires create_private_subnets = true. For database-only or intra-only VPCs without private subnets, set enable_nat_gateway = false."
    }

    precondition {
      condition     = length(var.firewall_subnets) == 0 || length(var.firewall_subnets) == local.az_count
      error_message = "firewall_subnets must be empty or have exactly ${local.az_count} entries (one per AZ); found ${length(var.firewall_subnets)}."
    }

    precondition {
      condition     = length(var.public_subnets) == 0 || length(var.public_subnets) == local.az_count
      error_message = "public_subnets must be empty or have exactly ${local.az_count} entries (one per AZ); found ${length(var.public_subnets)}."
    }

    precondition {
      condition     = length(var.private_subnets) == 0 || length(var.private_subnets) == local.az_count
      error_message = "private_subnets must be empty or have exactly ${local.az_count} entries (one per AZ); found ${length(var.private_subnets)}."
    }

    precondition {
      condition     = length(var.intra_subnets) == 0 || length(var.intra_subnets) == local.az_count
      error_message = "intra_subnets must be empty or have exactly ${local.az_count} entries (one per AZ); found ${length(var.intra_subnets)}."
    }
  }
}
