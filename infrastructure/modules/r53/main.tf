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
  source   = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/tags?ref=v2.5.0"
  for_each = var.resolver_endpoints

  context    = module.this.context
  attributes = concat(module.this.attributes, ["resolver-endpoint", each.key])
}

module "resolver_firewall_rule_group_label" {
  source   = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/tags?ref=v2.5.0"
  for_each = var.resolver_firewall_rule_groups

  context    = module.this.context
  attributes = concat(module.this.attributes, ["resolver-firewall", each.key])
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
  protocols  = each.value.protocols
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

module "resolver_firewall_rule_groups" {
  source  = "terraform-aws-modules/route53/aws//modules/resolver-firewall-rule-group"
  version = "6.5.0"

  for_each = module.this.enabled ? var.resolver_firewall_rule_groups : {}

  create                    = each.value.create
  name                      = coalesce(each.value.name, module.resolver_firewall_rule_group_label[each.key].id)
  ram_resource_associations = each.value.ram_resource_associations
  region                    = coalesce(each.value.region, var.aws_region)
  rules                     = each.value.rules
  tags                      = merge(module.resolver_firewall_rule_group_label[each.key].tags, each.value.tags)
}
