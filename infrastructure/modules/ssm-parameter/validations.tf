################################################################
# Input validation
#
# Validates cross-variable constraints that cannot be expressed
# through individual variable validation blocks:
#
#   * value and values are mutually exclusive — specify only one
#   * value_wo_version (write-only version trigger) only applies
#     to SecureString parameters
#   * At least one value source must be provided (value, values,
#     or value_wo_version)
################################################################

resource "terraform_data" "validations" {
  count = module.ssm_param_label.enabled ? 1 : 0

  lifecycle {
    precondition {
      condition     = !(var.value != null && length(var.values) > 0)
      error_message = "value and values are mutually exclusive; specify only one."
    }
    precondition {
      condition     = var.type != "SecureString" || var.value_wo_version == null || (var.value != null || var.value_wo_version != null)
      error_message = "value_wo_version is only valid when type is \"SecureString\"."
    }
    precondition {
      condition     = var.value != null || length(var.values) > 0 || var.value_wo_version != null
      error_message = "At least one of value, values, or value_wo_version must be provided."
    }
  }
}
