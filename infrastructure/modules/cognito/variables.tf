################################################################
# Naming overrides
################################################################

variable "user_pool_name" {
  description = "Override for the Cognito user pool name. Defaults to `<module.this.id>-users-pool`."
  type        = string
  default     = null
}

variable "domain" {
  description = "Optional Cognito user pool domain prefix. Defaults to `module.this.id`."
  type        = string
  default     = null
}

variable "app_client_name" {
  description = "Override for the default Cognito app client name. Defaults to `<module.this.id>-users-client`."
  type        = string
  default     = null
}

################################################################
# User pool configuration
################################################################

variable "user_pool_tier" {
  description = "Cognito User Pool tier. LITE avoids iam:PassRole requirements from ESSENTIALS/PLUS threat-protection features. Valid values: LITE, ESSENTIALS, PLUS."
  type        = string
  default     = "LITE"
  validation {
    condition     = contains(["LITE", "ESSENTIALS", "PLUS"], var.user_pool_tier)
    error_message = "user_pool_tier must be one of: LITE, ESSENTIALS, PLUS."
  }
}

variable "recovery_mechanisms" {
  description = "Account recovery mechanisms for the user pool. Defaults to email only. Avoid including verified_phone_number unless an explicit sms_configuration SNS caller role is provided — doing so forces iam:PassRole on the caller role which may be denied by restrictive IAM policies."
  type = list(object({
    name     = string
    priority = number
  }))
  default = [
    {
      name     = "verified_email"
      priority = 1
    }
  ]
}

variable "password_policy" {
  description = "Password policy for the Cognito user pool."
  type = object({
    minimum_length                   = optional(number, 8)
    require_lowercase                = optional(bool, true)
    require_numbers                  = optional(bool, true)
    require_symbols                  = optional(bool, true)
    require_uppercase                = optional(bool, true)
    temporary_password_validity_days = optional(number, 7)
    password_history_size            = optional(number, 0)
  })
  default = {}
}

variable "deletion_protection" {
  description = "Deletion protection setting for the user pool. Valid values are ACTIVE and INACTIVE."
  type        = string
  default     = "INACTIVE"

  validation {
    condition     = contains(["ACTIVE", "INACTIVE"], var.deletion_protection)
    error_message = "Allowed values: `ACTIVE`, `INACTIVE`."
  }
}

variable "mfa_configuration" {
  description = "MFA setting for the user pool. Valid values are ON, OFF, or OPTIONAL."
  type        = string
  default     = "OFF"

  validation {
    condition     = contains(["ON", "OFF", "OPTIONAL"], var.mfa_configuration)
    error_message = "Allowed values: `ON`, `OFF`, `OPTIONAL`."
  }
}

variable "attribute_names" {
  description = "Compatibility list of simple string schema attributes. Used to derive string_schemas when string_schemas is empty."
  type        = list(string)
  default     = ["acr", "amr", "email", "idassurancelevel", "nhsid_nrbac_roles", "bcss_username", "sid", "uid"]
}

################################################################
# Application clients
################################################################

variable "app_clients" {
  description = "List of Cognito application clients to create. This wrapper intentionally supports the shared-resources OAuth client pattern rather than the full upstream clients surface."
  type = list(object({
    name                                          = optional(string)
    callback_urls                                 = list(string)
    logout_urls                                   = optional(list(string), [])
    default_redirect_uri                          = optional(string)
    generate_secret                               = optional(bool, true)
    auth_session_validity                         = optional(number, 3)
    enable_propagate_additional_user_context_data = optional(bool, false)
    id_token_validity                             = optional(number, 1)    # hours (Cognito default unit)
    refresh_token_validity                        = optional(number, 30)   # days  (Cognito default unit)
    prevent_user_existence_errors                 = optional(string)
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

################################################################
# Bootstrap users
################################################################

variable "create" {
  description = "Determines whether Cognito resources will be created."
  type        = bool
  default     = true
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

variable "message_action" {
  description = "Message action for bootstrap Cognito user creation. Defaults to SUPPRESS to match the current BCSS stacks."
  type        = string
  default     = "SUPPRESS"

  validation {
    condition     = contains(["SUPPRESS", "RESEND"], var.message_action)
    error_message = "Allowed values: `SUPPRESS`, `RESEND`."
  }
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

# tflint-ignore: terraform_unused_declarations
variable "user_password" {
  description = "Fallback password for bootstrap Cognito users when an individual bootstrap_users entry does not provide user_password."
  type        = string
  default     = "changeme"
  sensitive   = true
}
