################################################################
# Route53 Module
#
# Screening wrapper around the community
# `terraform-aws-modules/route53/aws` modules:
#   - root module                       -> hosted zones, records, DNSSEC
#   - modules/resolver-endpoint        -> Route53 Resolver endpoints and rules
#   - modules/resolver-firewall-rule-group -> Resolver DNS Firewall rule groups
#
# Naming and tagging are derived from context.tf via module.this.
################################################################

module "resolver_endpoint_label" {
  source   = "../tags"
  for_each = var.resolver_endpoints

  context    = module.this.context
  attributes = concat(module.this.attributes, ["resolver-endpoint", each.key])
}

module "resolver_firewall_rule_group_label" {
  source   = "../tags"
  for_each = var.resolver_firewall_rule_groups

  context    = module.this.context
  attributes = concat(module.this.attributes, ["resolver-firewall", each.key])
}

module "resolver_firewall_association_label" {
  source   = "../tags"
  for_each = module.this.enabled ? local.firewall_vpc_associations : {}

  context         = module.this.context
  attributes      = concat(module.this.attributes, ["resolver-fw-assoc", each.key])
  id_length_limit = 64
}

module "hosted_zones" {
  source  = "terraform-aws-modules/route53/aws"
  version = "6.5.0"

  for_each = module.this.enabled ? var.hosted_zones : {}

  comment                        = each.value.comment
  create                         = each.value.create
  create_dnssec_kms_key          = each.value.create_dnssec_kms_key
  create_zone                    = each.value.create_zone
  delegation_set_id              = each.value.delegation_set_id
  dnssec_key_signing_key_name    = each.value.dnssec_key_signing_key_name
  dnssec_kms_key_aliases         = each.value.dnssec_kms_key_aliases
  dnssec_kms_key_arn             = each.value.dnssec_kms_key_arn
  dnssec_kms_key_description     = each.value.dnssec_kms_key_description
  dnssec_kms_key_tags            = merge(module.this.tags, each.value.dnssec_kms_key_tags)
  enable_accelerated_recovery    = each.value.enable_accelerated_recovery
  enable_dnssec                  = each.value.enable_dnssec
  force_destroy                  = each.value.force_destroy
  ignore_vpc                     = each.value.ignore_vpc
  name                           = each.value.name
  private_zone                   = each.value.private_zone
  records                        = each.value.records
  tags                           = merge(module.this.tags, each.value.tags)
  timeouts                       = each.value.timeouts
  vpc                            = each.value.vpc
  vpc_association_authorizations = each.value.vpc_association_authorizations
  vpc_id                         = each.value.vpc_id
}

module "resolver_endpoints" {
  source  = "terraform-aws-modules/route53/aws//modules/resolver-endpoint"
  version = "6.5.0"

  for_each = module.this.enabled ? var.resolver_endpoints : {}

  create     = each.value.create
  direction  = each.value.direction
  ip_address = each.value.ip_address
  name       = coalesce(each.value.name, module.resolver_endpoint_label[each.key].id)
  protocols  = length(each.value.protocols) > 0 ? each.value.protocols : ["Do53"]
  region     = coalesce(each.value.region, var.aws_region)
  rules      = each.value.rules
  tags       = merge(module.resolver_endpoint_label[each.key].tags, each.value.tags)
  type       = each.value.type

  create_security_group          = each.value.create_security_group
  security_group_description     = each.value.security_group_description
  security_group_egress_rules    = each.value.security_group_egress_rules
  security_group_ids             = each.value.security_group_ids
  security_group_ingress_rules   = each.value.security_group_ingress_rules
  security_group_name            = coalesce(each.value.security_group_name, module.resolver_endpoint_label[each.key].id)
  security_group_tags            = merge(module.resolver_endpoint_label[each.key].tags, each.value.security_group_tags)
  security_group_use_name_prefix = each.value.security_group_use_name_prefix
  vpc_id                         = each.value.vpc_id
}

################################################################
# Firewall Rule Groups
#
# UPSTREAM DEFECT (terraform-aws-modules/route53/aws v6.5.0)
# ──────────────────────────────────────────────────────────
# The community resolver-firewall-rule-group submodule creates
# an `aws_route53_resolver_firewall_domain_list` for EVERY rule
# in the `rules` map, regardless of whether a rule already
# supplies its own `firewall_domain_list_id` (e.g. an AWS-
# managed threat list or a RAM-shared domain list).
#
# In the rule resource it uses:
#   firewall_domain_list_id = try(
#     coalesce(each.value.firewall_domain_list_id,
#              aws_route53_resolver_firewall_domain_list.this[each.key].id),
#     null)
#
# So the provided ID takes precedence, but the duplicate
# customer-owned domain list is still created as an empty
# orphan. This wastes resources and causes confusion in the
# console (e.g. 4 empty customer-owned lists alongside 4 AWS-
# managed lists for the same threat categories).
#
# WORKAROUND
# ──────────
# We split each rule group's rules into two sets:
#
#   1. "domain" rules – rules where `domains` is populated and
#      `firewall_domain_list_id` is null. These are passed to
#      the community module which correctly creates a domain
#      list and wires it to the rule.
#
#   2. "external" rules – rules where `firewall_domain_list_id`
#      is set (AWS-managed lists, RAM-shared lists, or any
#      pre-existing list). These bypass the community module
#      entirely and are created as standalone
#      `aws_route53_resolver_firewall_rule` resources attached
#      to the same rule group.
#
# REVERT INSTRUCTIONS (when upstream is fixed)
# ─────────────────────────────────────────────
# Once the community module conditionally creates domain lists
# only for rules that do NOT supply `firewall_domain_list_id`:
#
#   1. Remove the `firewall_domain_rules` and
#      `firewall_external_rules` locals below.
#   2. Remove the `aws_route53_resolver_firewall_rule.external`
#      resource block.
#   3. Change `module.resolver_firewall_rule_groups` to pass
#      `rules = each.value.rules` instead of
#      `rules = local.firewall_domain_rules[each.key]`.
#   4. Run `terraform plan` to confirm the external rules are
#      adopted by the community module with no diff.
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

module "resolver_firewall_rule_groups" {
  source  = "terraform-aws-modules/route53/aws//modules/resolver-firewall-rule-group"
  version = "6.5.0"

  for_each = module.this.enabled ? var.resolver_firewall_rule_groups : {}

  create                    = each.value.create
  name                      = coalesce(each.value.name, module.resolver_firewall_rule_group_label[each.key].id)
  ram_resource_associations = each.value.ram_resource_associations
  region                    = coalesce(each.value.region, var.aws_region)
  rules                     = local.firewall_domain_rules[each.key]
  tags                      = merge(module.resolver_firewall_rule_group_label[each.key].tags, each.value.tags)
}

# Standalone rules for existing/AWS-managed domain lists.
# These bypass the community module to avoid orphan domain list
# creation (see UPSTREAM DEFECT comment above).
# REVERT: Remove this resource block once the upstream fix lands.
resource "aws_route53_resolver_firewall_rule" "external" {
  for_each = module.this.enabled ? local.firewall_external_rules : {}

  action                             = each.value.action
  block_override_dns_type            = each.value.block_override_dns_type
  block_override_domain              = each.value.block_override_domain
  block_override_ttl                 = each.value.block_override_ttl
  block_response                     = each.value.block_response
  firewall_domain_list_id            = each.value.firewall_domain_list_id
  firewall_domain_redirection_action = each.value.firewall_domain_redirection_action
  firewall_rule_group_id             = module.resolver_firewall_rule_groups[each.value.group_key].id
  name                               = coalesce(each.value.name, element(split("/", each.key), 1))
  priority                           = each.value.priority
  q_type                             = each.value.q_type
}

################################################################
# Firewall Rule Group VPC Associations
#
# The community module does not create VPC associations, so we
# create them here.
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

resource "aws_route53_resolver_firewall_rule_group_association" "this" {
  for_each = module.this.enabled ? local.firewall_vpc_associations : {}

  name                   = module.resolver_firewall_association_label[each.key].id
  firewall_rule_group_id = module.resolver_firewall_rule_groups[each.value.group_key].id
  vpc_id                 = each.value.vpc_id
  priority               = each.value.priority

  tags = module.resolver_firewall_association_label[each.key].tags
}
