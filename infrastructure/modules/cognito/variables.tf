variable "create" {
  description = "Determines whether Cognito resources will be created."
  type        = bool
  default     = true
}

variable "user_pool_name" {
  description = "Optional explicit Cognito user pool name. Defaults to name_prefix when set, otherwise the shared context-derived module ID."
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "Compatibility alias for older callers. Used as the default user pool and domain prefix when user_pool_name or domain are unset."
  type        = string
  default     = null
}

variable "create_domain" {
  description = "Whether to create a Cognito user pool domain."
  type        = bool
  default     = true
}

variable "domain" {
  description = "Optional Cognito user pool domain prefix or custom domain. Defaults to name_prefix or the resolved user pool name when create_domain is true."
  type        = string
  default     = null
}

variable "domain_certificate_arn" {
  description = "Optional ACM certificate ARN in us-east-1 for a custom Cognito domain."
  type        = string
  default     = null
}

variable "domain_managed_login_version" {
  description = "Managed login version for the Cognito domain. Use 1 for classic hosted UI or 2 for managed login."
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 2], var.domain_managed_login_version)
    error_message = "domain_managed_login_version must be 1 or 2."
  }
}

variable "user_pool_tier" {
  description = "Cognito user pool tier. Valid values are LITE, ESSENTIALS, and PLUS."
  type        = string
  default     = "ESSENTIALS"

  validation {
    condition     = contains(["LITE", "ESSENTIALS", "PLUS"], var.user_pool_tier)
    error_message = "user_pool_tier must be one of LITE, ESSENTIALS, or PLUS."
  }
}

variable "deletion_protection" {
  description = "Deletion protection setting for the user pool. Valid values are ACTIVE and INACTIVE."
  type        = string
  default     = "INACTIVE"
}

variable "mfa_configuration" {
  description = "MFA setting for the user pool. Valid values are ON, OFF, or OPTIONAL."
  type        = string
  default     = "OFF"
}

variable "alias_attributes" {
  description = "Attributes supported as aliases for the user pool. Conflicts with username_attributes in Cognito."
  type        = list(string)
  default     = null
}

variable "username_attributes" {
  description = "Attributes that can be used as usernames when users sign up. Defaults to the current bespoke behavior when left unset."
  type        = list(string)
  default     = []
}

variable "auto_verified_attributes" {
  description = "Attributes to auto-verify in the user pool."
  type        = list(string)
  default     = ["email"]
}

variable "attribute_names" {
  description = "Compatibility list of simple string schema attributes. Used to derive string_schemas when string_schemas is empty."
  type        = list(string)
  default     = ["acr", "amr", "email", "idassurancelevel", "nhsid_nrbac_roles", "bss_username", "sid", "uid"]
}

variable "string_schemas" {
  description = "Explicit Cognito string schema definitions. When set, these override the derived schemas from attribute_names."
  type        = list(any)
  default     = []
}

variable "admin_create_user_config" {
  description = "AdminCreateUser configuration forwarded to the upstream module. Defaults to allow_admin_create_user_only = false to match the bespoke module behavior."
  type        = any
  default     = null
}

variable "email_configuration" {
  description = "Email configuration forwarded to the upstream module. Defaults to Cognito-managed email sending."
  type        = any
  default     = null
}

variable "password_policy" {
  description = "Password policy forwarded to the upstream module. Defaults match the current bespoke module."
  type        = any
  default     = null
}

variable "recovery_mechanisms" {
  description = "Account recovery mechanisms. Defaults to verified email first, then verified phone number."
  type        = list(any)
  default     = []
}

variable "username_configuration" {
  description = "Username configuration forwarded to the upstream module. Defaults to case_sensitive = false."
  type        = any
  default     = null
}

variable "verification_message_template" {
  description = "Verification message template forwarded to the upstream module. Defaults to CONFIRM_WITH_CODE."
  type        = any
  default     = null
}

variable "user_pool_add_ons_advanced_security_mode" {
  description = "Advanced security mode for Cognito user pool add-ons."
  type        = string
  default     = null
}

variable "user_pool_add_ons_advanced_security_additional_flows" {
  description = "Additional advanced security configuration for custom authentication flows."
  type        = string
  default     = null
}

variable "sign_in_policy" {
  description = "Optional sign-in policy configuration."
  type        = any
  default     = null
}

variable "software_token_mfa_configuration" {
  description = "Optional software token MFA configuration."
  type        = any
  default     = {}
}

variable "sms_configuration" {
  description = "Optional SMS configuration for the user pool."
  type        = any
  default     = {}
}

variable "email_mfa_configuration" {
  description = "Optional email MFA configuration."
  type        = any
  default     = null
}

variable "user_attribute_update_settings" {
  description = "Optional user attribute update settings."
  type        = any
  default     = null
}

variable "lambda_config" {
  description = "Optional Lambda trigger configuration for Cognito."
  type        = any
  default     = {}
}

variable "app_clients" {
  description = "List of Cognito application clients to create. This wrapper intentionally supports the shared-resources OAuth client pattern rather than the full upstream clients surface."
  type = list(object({
    name                                          = optional(string)
    callback_urls                                 = list(string)
    logout_urls                                   = optional(list(string), [])
    default_redirect_uri                          = optional(string)
    generate_secret                               = optional(bool, true)
    auth_session_validity                         = optional(number, 3)
    allowed_oauth_flows_user_pool_client          = optional(bool, true)
    allowed_oauth_flows                           = optional(list(string), ["code"])
    allowed_oauth_scopes                          = optional(list(string), ["email", "openid", "profile", "aws.cognito.signin.user.admin"])
    explicit_auth_flows                           = optional(list(string), ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_USER_PASSWORD_AUTH"])
    supported_identity_providers                  = optional(list(string), ["COGNITO"])
    enable_propagate_additional_user_context_data = optional(bool, false)
    access_token_validity                         = optional(number)
    id_token_validity                             = optional(number)
    refresh_token_validity                        = optional(number)
    token_validity_units                          = optional(map(string))
    prevent_user_existence_errors                 = optional(string)
    read_attributes                               = optional(list(string), [])
    write_attributes                              = optional(list(string), [])
    enable_token_revocation                       = optional(bool, true)
  }))
  default = []

  validation {
    condition = alltrue([
      for client in var.app_clients :
      try(client.default_redirect_uri, null) == null || contains(client.callback_urls, client.default_redirect_uri)
    ])
    error_message = "Each app_clients.default_redirect_uri must also appear in app_clients.callback_urls."
  }
}

variable "bootstrap_users" {
  description = "Optional list of bootstrap Cognito users to create. This covers the current BCSS stack pattern where initial training or shared users are provisioned during stack deployment."
  type = list(object({
    uuid               = string
    bcss_username      = string
    id_assurance_level = string
    rbac_role          = string
    user_password      = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for user in var.bootstrap_users :
      user.uuid != "" && user.bcss_username != "" && user.id_assurance_level != "" && user.rbac_role != ""
    ])
    error_message = "Each bootstrap user must include non-empty uuid, bcss_username, id_assurance_level, and rbac_role values."
  }
}

variable "managed_login_branding_enabled" {
  description = "Whether to enable Cognito managed login branding. Requires the awscc provider in the calling root module."
  type        = bool
  default     = false
}

variable "managed_login_branding" {
  description = "Managed login branding definitions forwarded to the upstream module when enabled."
  type        = any
  default     = {}
}

variable "ignore_schema_changes" {
  description = "Whether to enable the upstream schema ignore-changes workaround. Recommended for new deployments using custom schemas."
  type        = bool
  default     = true
}

variable "message_action" {
  description = "Message action for bootstrap Cognito user creation. Defaults to SUPPRESS to match the current BCSS stacks."
  type        = string
  default     = "SUPPRESS"
}

variable "acr" {
  description = "ACR attribute applied to bootstrap Cognito users."
  type        = string
  default     = "AAL1_USERPASS"
}

variable "amr" {
  description = "AMR attribute applied to bootstrap Cognito users."
  type        = string
  default     = "USERPASS"
}

variable "user_email" {
  description = "Email attribute applied to bootstrap Cognito users."
  type        = string
  default     = "nhsdigital.axe@nhs.net"
}

variable "user_password" {
  description = "Fallback password for bootstrap Cognito users when an individual bootstrap_users entry does not provide user_password."
  type        = string
  default     = "changeme"
  sensitive   = true
}

variable "recovery_window" {
  description = "Deprecated compatibility input from the bespoke BS-Select bootstrap-user secret flow. No longer used by this wrapper."
  type        = number
  default     = null
}

variable "secret_replication_regions" {
  description = "Deprecated compatibility input from the bespoke BS-Select bootstrap-user secret flow. No longer used by this wrapper."
  type        = list(string)
  default     = []
}
