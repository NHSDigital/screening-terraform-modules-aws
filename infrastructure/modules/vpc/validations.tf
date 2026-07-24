################################################################
# Input validation
#
# Validates cross-variable constraints that cannot be expressed
# through individual variable validation blocks:
#
#   * At least one subnet type must be enabled (create_* flag = true)
#   * enable_network_firewall requires firewall subnets to be created
#   * single_nat_gateway only makes sense if private subnets exist
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

    precondition {
      condition     = !var.enable_network_firewall || var.create_firewall_subnets
      error_message = "enable_network_firewall = true requires create_firewall_subnets = true."
    }

    precondition {
      condition     = !var.single_nat_gateway || var.create_private_subnets
      error_message = "single_nat_gateway = true requires create_private_subnets = true (NAT gateway must route traffic to private subnets)."
    }

    precondition {
      condition = length(var.firewall_subnets) == 0 || length(var.firewall_subnets) == local.az_count
      error_message = "firewall_subnets must be empty or have exactly ${local.az_count} entries (one per AZ); found ${length(var.firewall_subnets)}."
    }

    precondition {
      condition = length(var.public_subnets) == 0 || length(var.public_subnets) == local.az_count
      error_message = "public_subnets must be empty or have exactly ${local.az_count} entries (one per AZ); found ${length(var.public_subnets)}."
    }

    precondition {
      condition = length(var.private_subnets) == 0 || length(var.private_subnets) == local.az_count
      error_message = "private_subnets must be empty or have exactly ${local.az_count} entries (one per AZ); found ${length(var.private_subnets)}."
    }

    precondition {
      condition = length(var.intra_subnets) == 0 || length(var.intra_subnets) == local.az_count
      error_message = "intra_subnets must be empty or have exactly ${local.az_count} entries (one per AZ); found ${length(var.intra_subnets)}."
    }
  }
}
