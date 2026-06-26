module "ssm_parameter" {
  source  = "terraform-aws-modules/ssm-parameter/aws"
  version = "2.1.0"

  create = module.this.enabled
  name   = local.name
  tags   = module.this.tags

  allowed_pattern      = var.allowed_pattern
  data_type            = var.ssm_data_type
  description          = var.description
  ignore_value_changes = var.ignore_value_changes
  key_id               = var.key_id
  overwrite            = var.overwrite
  secure_type          = var.type == "SecureString"
  tier                 = var.tier
  type                 = var.type
  value                = var.value
  value_wo_version     = var.value_wo_version
  values               = var.values
}
