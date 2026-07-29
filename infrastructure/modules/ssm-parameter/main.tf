################################################################
# SSM Parameter
#
# Thin NHS wrapper around the community ssm-parameter module
# that enforces the screening platform's baseline controls:
#
#   * Naming:        derived from context labels via module.ssm_param_label.id
#   * Tagging:       all NHS-required tags applied via module.ssm_param_label.tags
#   * SecureString:  KMS key_id is mandatory (enforced via validation)
#   * Enabled flag:  create = module.ssm_param_label.enabled
#
# Cross-variable input constraints are enforced in validations.tf.
################################################################

module "ssm_param_label" {
  source = "../tags"

  # Allow forward slashes for hierarchical parameter names
  regex_replace_chars = "/[^a-zA-Z0-9-_\\/]/"

  context = module.this.context
}

module "ssm_parameter" {
  source  = "terraform-aws-modules/ssm-parameter/aws"
  version = "2.1.0"

  create = module.ssm_param_label.enabled
  name   = local.parameter_name
  tags   = module.ssm_param_label.tags

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
