variable "create" {
  description = "Determines whether Cognito resources will be created."
  type        = bool
  default     = true
}

variable "name_prefix" {
  description = "Compatibility alias for older callers. Used as the default user pool and domain prefix when user_pool_name or domain are unset."
  type        = string
  default     = null
}

variable "domain" {
  description = "Optional Cognito user pool domain prefix. Defaults to name_prefix or the resolved user pool name."
  type        = string
  default     = null
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

variable "attribute_names" {
  description = "Compatibility list of simple string schema attributes. Used to derive string_schemas when string_schemas is empty."
  type        = list(string)
  default     = ["acr", "amr", "email", "idassurancelevel", "nhsid_nrbac_roles", "bcss_username", "sid", "uid"]
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
    enable_propagate_additional_user_context_data = optional(bool, false)
    id_token_validity                             = optional(number)
    refresh_token_validity                        = optional(number)
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
