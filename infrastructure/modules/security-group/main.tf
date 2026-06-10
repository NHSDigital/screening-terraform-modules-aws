module "security_group" {
  source = "terraform-aws-modules/security-group/aws"

  create = module.this.enabled
  name   = module.this.id
  tags   = module.this.tags

  description = var.description

  vpc_id = var.vpc_id

  egress_rules  = var.egress_rules
  ingress_rules = var.ingress_rules
}
