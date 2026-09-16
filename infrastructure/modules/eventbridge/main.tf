module "eventbridge" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eventbridge.git?ref=f9934726324c988f823682884b4fa003586a7b6f" # v4.3.2

  create = module.this.enabled
  tags   = module.this.tags

  # DAVEH: add attributes
}
