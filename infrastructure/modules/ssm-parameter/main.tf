module "ssm_parameter" {
  source  = "terraform-aws-modules/ssm-parameter/aws"
  version = "~> 2.1.0"

  create = module.this.enabled
  name   = module.this.name
  tags   = module.this.tags
}
