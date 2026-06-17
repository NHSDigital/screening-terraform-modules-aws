####################################################################################
# BSS COMMON
####################################################################################

variable "name_prefix" {
  description = "The account, environment etc"
  type        = string
}

# tflint-ignore: terraform_unused_declarations
variable "environment" {
  description = "The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD"
  type        = string
}

##################################################################################
# COGNITO
##################################################################################
variable "deletion_protection" {
  description = "Whether user pool deletion protection is enabled"
  type        = string
  default     = "INACTIVE"
}

variable "mfa_configuration" {
  description = "MFA mode for the user pool"
  type        = string
  default     = "OFF"
}

variable "attribute_names" {
  description = "Cognito custom attributes to create"
  type        = list(string)
  default     = ["acr", "amr", "email", "idassurancelevel", "nhsid_nrbac_roles", "bss_username", "sid", "uid"]
}

variable "message_action" {
  description = "Message action used when creating users"
  type        = string
  default     = "SUPPRESS"
}

variable "acr" {
  description = "Default ACR value for user attributes"
  type        = string
  default     = "AAL1_USERPASS"
}

variable "amr" {
  description = "Default AMR value for user attributes"
  type        = string
  default     = "USERPASS"
}

variable "user_email" {
  description = "Initial user email address"
  type        = string
  default     = "nhsdigital.axe@nhs.net"
}

# tflint-ignore: terraform_unused_declarations
variable "user_password" {
  description = "Initial user password placeholder"
  type        = string
  default     = "changeme"
}

variable "recovery_window" {
  description = "The number of days that credentials should be retained for"
  type        = number
}

variable "secret_replication_regions" {
  description = "List of additional regions where created secrets should be replicated"
  type        = list(string)
}
