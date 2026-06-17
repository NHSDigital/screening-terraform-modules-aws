# DAVEH

module "iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.6.1"

  create = module.this.enabled
  name   = module.this.id
  tags   = module.this.tags

  description = var.description
  path        = var.path
  policy      = var.policy

  # `name_prefix` conflicts with `name`, hence we omit it
}
