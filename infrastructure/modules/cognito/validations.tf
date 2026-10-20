################################################################
# Input validation
#
# Validates cross-variable constraints that cannot be expressed
# through individual variable validation blocks:
#
#   * Every supplied bootstrap user password (per-user or the
#     user_password fallback) satisfies password_policy
################################################################

resource "terraform_data" "validations" {
  count = module.this.enabled && var.create ? 1 : 0

  lifecycle {
    precondition {
      # The result is a bool derived from sensitive passwords; it reveals no secret.
      condition     = nonsensitive(local.bootstrap_user_passwords_meet_policy)
      error_message = "Every bootstrap user password (bootstrap_users[*].user_password or the user_password fallback) must satisfy password_policy (minimum_length, required character classes) and be at most 256 characters. Set user_password = null to let Cognito generate a temporary password instead."
    }
  }
}
