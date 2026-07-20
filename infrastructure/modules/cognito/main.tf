################################################################
# Cognito User Pool
#
# Thin NHS wrapper around the lgallard/cognito-user-pool/aws
# community module that enforces the screening platform's
# baseline controls:
#
#   * Password policy (minimum length, complexity, history)
#   * Email-only auto-verification and account recovery
#   * Token revocation enabled on all app clients by default
#   * Schema changes ignored after initial deployment
#   * Resources tagged via module.this.tags
#   * Creation gated by module.this.enabled
#
# Naming and tagging are derived from context.tf via module.this.
# Derived locals (naming, client config) are defined in locals.tf.
################################################################

module "cognito" {
  source  = "lgallard/cognito-user-pool/aws"
  version = "4.0.2"

  enabled = module.this.enabled

  user_pool_name           = local.user_pool_name
  domain                   = local.domain_name
  deletion_protection      = var.deletion_protection
  auto_verified_attributes = ["email"]
  mfa_configuration        = var.mfa_configuration
  user_pool_tier           = var.user_pool_tier

  admin_create_user_config      = local.default_admin_create_user_config
  email_configuration           = local.default_email_configuration
  password_policy               = var.password_policy
  recovery_mechanisms           = var.recovery_mechanisms
  string_schemas                = local.default_string_schemas
  username_configuration        = local.default_username_configuration
  verification_message_template = local.default_verification_message_template
  clients                       = local.cognito_clients
  ignore_schema_changes         = true

  tags = module.this.tags
}

resource "aws_cognito_user" "bootstrap_users" {
  for_each = module.this.enabled && var.create ? { for user in var.bootstrap_users : user.uuid => user } : {}

  user_pool_id   = module.cognito.id
  username       = each.value.bcss_username
  password       = coalesce(try(each.value.user_password, null), var.user_password)
  message_action = var.message_action

  attributes = {
    acr               = var.acr
    amr               = var.amr
    email             = var.user_email
    email_verified    = true
    idassurancelevel  = each.value.id_assurance_level
    nhsid_nrbac_roles = each.value.rbac_role
    bcss_username     = each.value.bcss_username
    sid               = each.value.uuid
    uid               = each.value.uuid
  }
}
