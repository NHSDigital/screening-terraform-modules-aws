################################################################
# Locals — Firewall Rule Group helpers
#
# These locals support the upstream defect workaround documented
# in main.tf. See the REVERT INSTRUCTIONS comment there for
# removal guidance once the upstream fix lands.
################################################################

locals {
  # Rules that create their own domain list (passed to community module)
  firewall_domain_rules = {
    for gk, g in var.resolver_firewall_rule_groups : gk => {
      for rk, r in g.rules : rk => r
      if r.firewall_domain_list_id == null
    }
  }

  # Rules that reference an existing domain list (standalone resources)
  firewall_external_rules = merge([
    for gk, g in var.resolver_firewall_rule_groups : {
      for rk, r in g.rules : "${gk}/${rk}" => merge(r, { group_key = gk })
      if r.firewall_domain_list_id != null
    }
  ]...)
}

################################################################
# Locals — Firewall Rule Group VPC Associations
################################################################

locals {
  firewall_vpc_associations = merge([
    for group_key, group in var.resolver_firewall_rule_groups : {
      for vpc_key, vpc_id in group.vpc_ids :
      "${group_key}-${vpc_key}" => {
        group_key = group_key
        vpc_id    = vpc_id
        priority  = group.priority
      }
    }
  ]...)
}
