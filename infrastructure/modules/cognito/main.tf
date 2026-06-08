data "aws_ssm_parameter" "bootstrap_users" {
  count = module.this.enabled && var.create && var.bootstrap_users_ssm_parameter_name != null ? 1 : 0

  name = var.bootstrap_users_ssm_parameter_name
}

locals {
  user_pool_name          = coalesce(var.name_prefix != null ? "${var.name_prefix}-users-pool" : null, module.this.id)
  domain_name             = coalesce(var.domain, var.name_prefix, local.user_pool_name)
  default_app_client_name = coalesce(var.name_prefix != null ? "${var.name_prefix}-users-client" : null, "${local.user_pool_name}-client")
  ssm_bootstrap_users     = var.bootstrap_users_ssm_parameter_name != null ? try(jsondecode(nonsensitive(data.aws_ssm_parameter.bootstrap_users[0].value)), []) : []
  resolved_bootstrap_users = length(var.bootstrap_users) > 0 ? var.bootstrap_users : local.ssm_bootstrap_users

  default_admin_create_user_config = {
    allow_admin_create_user_only = false
  }

  default_email_configuration = {
    email_sending_account = "COGNITO_DEFAULT"
  }

  default_password_policy = {
    minimum_length                   = 8
    require_lowercase                = false
    require_numbers                  = false
    require_symbols                  = false
    require_uppercase                = false
    temporary_password_validity_days = 7
  }

  default_recovery_mechanisms = [
    {
      name     = "verified_email"
      priority = 1
    },
    {
      name     = "verified_phone_number"
      priority = 2
    }
  ]

  default_username_configuration = {
    case_sensitive = false
  }

  default_verification_message_template = {
    default_email_option = "CONFIRM_WITH_CODE"
  }

  default_string_schemas = [
    for attribute_name in var.attribute_names : {
      attribute_data_type      = "String"
      developer_only_attribute = false
      mutable                  = true
      name                     = attribute_name
      required                 = false
      string_attribute_constraints = {
        min_length = "1"
        max_length = "256"
      }
    }
  ]

  cognito_clients = [
    for client in var.app_clients : {
      name                                          = try(client.name, local.default_app_client_name)
      callback_urls                                 = client.callback_urls
      logout_urls                                   = client.logout_urls
      default_redirect_uri                          = try(client.default_redirect_uri, null)
      generate_secret                               = try(client.generate_secret, true)
      auth_session_validity                         = try(client.auth_session_validity, 3)
      allowed_oauth_flows_user_pool_client          = true
      allowed_oauth_flows                           = ["code"]
      allowed_oauth_scopes                          = ["email", "openid", "profile", "aws.cognito.signin.user.admin"]
      explicit_auth_flows                           = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_USER_PASSWORD_AUTH"]
      supported_identity_providers                  = ["COGNITO"]
      enable_propagate_additional_user_context_data = try(client.enable_propagate_additional_user_context_data, false)
      access_token_validity                         = 60
      id_token_validity                             = try(client.id_token_validity, null)
      refresh_token_validity                        = try(client.refresh_token_validity, null)
      token_validity_units                          = { access_token = "minutes", id_token = "minutes", refresh_token = "days" }
      prevent_user_existence_errors                 = try(client.prevent_user_existence_errors, null)
      enable_token_revocation                       = try(client.enable_token_revocation, true)
    }
  ]
}

resource "random_password" "bootstrap_user_password" {
  count = module.this.enabled && var.create && length(local.resolved_bootstrap_users) > 0 ? 1 : 0

  length           = 20
  special          = true
  override_special = "!%^*-_+="
}

resource "aws_secretsmanager_secret" "bootstrap_user_password" {
  count = module.this.enabled && var.create && length(local.resolved_bootstrap_users) > 0 ? 1 : 0

  name                    = "${local.user_pool_name}-cognito-user"
  recovery_window_in_days = var.recovery_window

  dynamic "replica" {
    for_each = var.secret_replication_regions
    content {
      region = replica.value
    }
  }
}

resource "aws_secretsmanager_secret_version" "bootstrap_user_password" {
  count = module.this.enabled && var.create && length(local.resolved_bootstrap_users) > 0 ? 1 : 0

  secret_id = aws_secretsmanager_secret.bootstrap_user_password[0].id
  secret_string = jsonencode({
    password = coalesce(var.user_password, random_password.bootstrap_user_password[0].result)
  })
}

module "cognito" {
  source  = "lgallard/cognito-user-pool/aws"
  version = "4.0.2"

  enabled = module.this.enabled && var.create

  user_pool_name           = local.user_pool_name
  domain                   = local.domain_name
  deletion_protection      = var.deletion_protection
  auto_verified_attributes = ["email"]
  mfa_configuration        = var.mfa_configuration

  admin_create_user_config      = local.default_admin_create_user_config
  email_configuration           = local.default_email_configuration
  password_policy               = local.default_password_policy
  recovery_mechanisms           = local.default_recovery_mechanisms
  string_schemas                = local.default_string_schemas
  username_configuration        = local.default_username_configuration
  verification_message_template = local.default_verification_message_template
  clients                       = local.cognito_clients
  ignore_schema_changes         = true

  tags = module.this.tags
}

resource "aws_cognito_user" "bootstrap_users" {
  for_each = module.this.enabled && var.create ? { for user in local.resolved_bootstrap_users : user.uuid => user } : {}

  user_pool_id   = module.cognito.id
  username       = coalesce(try(each.value.bss_username, null), try(each.value.bcss_username, null))
  password       = coalesce(try(each.value.user_password, null), var.user_password, random_password.bootstrap_user_password[0].result)
  message_action = var.message_action

  attributes = {
    acr               = var.acr
    amr               = var.amr
    email             = var.user_email
    email_verified    = true
    idassurancelevel  = each.value.id_assurance_level
    nhsid_nrbac_roles = each.value.rbac_role
    bss_username      = coalesce(try(each.value.bss_username, null), try(each.value.bcss_username, null))
    sid               = each.value.uuid
    uid               = each.value.uuid
  }
}
