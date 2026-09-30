################################################################
# SSM Parameter (write-only)
#
# Native NHS module for aws_ssm_parameter that enforces the
# screening platform's baseline controls:
#
#   * Naming:        derived from context labels via module.ssm_param_label.id
#   * Tagging:       all NHS-required tags applied via module.ssm_param_label.tags
#   * SecureString:  KMS key_id is mandatory; values are only ever sent via the
#                    write-only value_wo argument, so they never reach state or plan
#   * Ephemeral:     value_wo accepts ephemeral values (e.g. ephemeral resources)
#   * Versioning:    value_wo_version is mandatory for SecureString (no silent default)
#   * Enabled flag:  resources gated on module.ssm_param_label.enabled
#
# Declares aws_ssm_parameter directly rather than wrapping
# terraform-aws-modules/ssm-parameter, whose non-ephemeral value
# input cannot accept ephemeral values.
#
# Cross-variable input constraints are enforced by variable
# validations in variables.tf.
################################################################

module "ssm_param_label" {
  source = "../tags"

  # Allow forward slashes for hierarchical parameter names
  regex_replace_chars = "/[^a-zA-Z0-9-_\\/]/"

  context = module.this.context
}

resource "aws_ssm_parameter" "this" {
  count = module.ssm_param_label.enabled && !var.ignore_value_changes ? 1 : 0

  name            = local.parameter_name
  type            = var.type
  description     = var.description
  tier            = var.tier
  data_type       = var.ssm_data_type
  allowed_pattern = var.allowed_pattern
  overwrite       = var.overwrite
  key_id          = local.secure_type ? var.key_id : null

  insecure_value   = local.plain_value
  value_wo         = local.secure_type ? (var.value_wo != null ? var.value_wo : var.value) : null
  value_wo_version = local.secure_type ? var.value_wo_version : null

  tags = module.ssm_param_label.tags
}

resource "aws_ssm_parameter" "ignore_value" {
  count = module.ssm_param_label.enabled && var.ignore_value_changes ? 1 : 0

  # Both resources share one parameter name: this edge makes Terraform destroy the old
  # address before creating the new one when ignore_value_changes is toggled (either way).
  depends_on = [aws_ssm_parameter.this]

  name            = local.parameter_name
  type            = var.type
  description     = var.description
  tier            = var.tier
  data_type       = var.ssm_data_type
  allowed_pattern = var.allowed_pattern
  overwrite       = var.overwrite
  key_id          = local.secure_type ? var.key_id : null

  insecure_value   = local.plain_value
  value_wo         = local.secure_type ? (var.value_wo != null ? var.value_wo : var.value) : null
  value_wo_version = local.secure_type ? var.value_wo_version : null

  tags = module.ssm_param_label.tags

  lifecycle {
    ignore_changes = [
      insecure_value,
      value,
      value_wo,
      value_wo_version,
    ]
  }
}

################################################################
# Drop-in replacement for the ssm-parameter module: existing state
# moves in place when a caller switches its module source.
################################################################

moved {
  from = module.ssm_parameter.aws_ssm_parameter.this
  to   = aws_ssm_parameter.this
}

moved {
  from = module.ssm_parameter.aws_ssm_parameter.ignore_value
  to   = aws_ssm_parameter.ignore_value
}
