################################################################
# Secrets Manager secret
#
# Thin NHS wrapper around the community secrets-manager module
# that enforces the screening platform's baseline controls:
#
#   * Naming:        derived from context labels via module.secret_label.id
#   * Tagging:       all NHS-required tags applied via module.secret_label.tags
#   * Public policy: always blocked (block_public_policy = true)
#   * Enabled flag:  create = module.secret_label.enabled
#
# Inputs intentionally NOT exposed (hardcoded below):
#   - block_public_policy → always true; callers cannot override
#
# Cross-variable input constraints are enforced in validations.tf.
################################################################
module "secret_label" {
  source = "../tags"

  # Allow forward slashes for hierarchical secret names
  regex_replace_chars = "/[^a-zA-Z0-9-_\\/]/"

  context = module.this.context
}


module "secret" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  create = module.secret_label.enabled

  # Naming — always derived from context labels
  name = local.secret_name

  description             = var.description
  kms_key_id              = var.kms_key_id
  recovery_window_in_days = var.recovery_window_in_days

  # Secret value
  create_random_password           = var.create_random_password
  random_password_length           = var.random_password_length
  random_password_override_special = var.random_password_override_special
  secret_string                    = var.secret_string
  secret_string_wo                 = var.secret_string_wo
  secret_string_wo_version         = var.secret_string_wo_version
  ignore_secret_changes            = var.ignore_secret_changes

  # Policy
  create_policy       = var.create_policy
  block_public_policy = true # hardcoded — public access is never permitted
  policy_statements   = var.policy_statements

  # Rotation
  enable_rotation     = var.enable_rotation
  rotate_immediately  = var.rotate_immediately
  rotation_lambda_arn = var.rotation_lambda_arn
  rotation_rules      = var.rotation_rules

  # Tags — automatically populated from context
  tags = module.secret_label.tags
}
