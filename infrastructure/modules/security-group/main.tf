module "security_group" {
  source = "terraform-aws-modules/security-group/aws"

  create = module.this.enabled
  name = module.this.id
  tags = module.this.tags

  description = null # DAVEH

  vpc_id = null # DAVEH

  egress_rules = {} # DAVEH
  ingress_rules = {} # DAVEH
}
