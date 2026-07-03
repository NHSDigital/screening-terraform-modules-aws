################################################################
# Input validation
#
# Validates cross-variable constraints that cannot be expressed
# through individual variable validation blocks:
#
#   * secret_string, secret_string_wo, and create_random_password
#     are mutually exclusive — at most one may be set
#   * enable_rotation requires both rotation_lambda_arn and
#     rotation_rules to be provided
################################################################

resource "terraform_data" "validations" {
  count = module.this.enabled ? 1 : 0

  lifecycle {
    precondition {
      condition     = !(var.create_random_password && var.secret_string != null)
      error_message = "create_random_password and secret_string are mutually exclusive; set only one."
    }
    precondition {
      condition     = !(var.create_random_password && var.secret_string_wo != null)
      error_message = "create_random_password and secret_string_wo are mutually exclusive; set only one."
    }
    precondition {
      condition     = !(var.secret_string != null && var.secret_string_wo != null)
      error_message = "secret_string and secret_string_wo are mutually exclusive; set only one."
    }
    precondition {
      condition     = !var.enable_rotation || (var.rotation_lambda_arn != "" && var.rotation_rules != null)
      error_message = "enable_rotation requires both rotation_lambda_arn and rotation_rules to be set."
    }
  }
}
