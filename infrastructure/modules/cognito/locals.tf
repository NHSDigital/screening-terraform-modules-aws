locals {
  user_pool_name          = coalesce(var.user_pool_name, "${module.this.id}-users-pool")
  domain_name             = coalesce(var.domain, module.this.id)
  default_app_client_name = coalesce(var.app_client_name, "${module.this.id}-users-client")

  default_admin_create_user_config = {
    allow_admin_create_user_only = false
  }

  default_email_configuration = {
    email_sending_account = "COGNITO_DEFAULT"
  }

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
      access_token_validity                         = 1 # 1 hour (Cognito default unit: hours)
      id_token_validity                             = client.id_token_validity
      refresh_token_validity                        = client.refresh_token_validity
      # token_validity_units omitted — lgallard skips the block when absent;
      # Cognito default units apply: hours for access/id tokens, days for refresh
      prevent_user_existence_errors                 = try(client.prevent_user_existence_errors, null)
      enable_token_revocation                       = try(client.enable_token_revocation, true)
    }
  ]
}
