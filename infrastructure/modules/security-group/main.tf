################################################################
# Security Group
#
# Thin NHS wrapper around the community security-group module that
# enforces the screening platform's baseline controls:
#
#   * Exclusive rule enforcement: only rules defined in code
#     (via enable_exclusive_rules = true) exist on the group
#   * Naming: consistent via module.this.id with name prefix for
#     safe replacements
#   * Tagging: all resources tagged via module.this.tags
#   * Creation gate: controlled via module.this.enabled
#
# Naming and tagging are derived from context.tf via module.this.
################################################################

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "6.0.0"

  create                 = module.this.enabled
  name                   = local.security_group_name
  use_name_prefix        = var.use_name_prefix
  description            = var.description
  enable_exclusive_rules = var.enable_exclusive_rules
  revoke_rules_on_delete = var.revoke_rules_on_delete

  egress_rules  = var.egress_rules
  ingress_rules = var.ingress_rules

  vpc_id = var.vpc_id

  tags = module.this.tags
}
