module "ssm_parameter" {
  source  = "terraform-aws-modules/ssm-parameter/aws"
  version = "~> 2.1.0"

  create = module.this.enabled
  name   = local.name # if it's a path, it must be fully qualified
  tags   = module.this.tags
}
