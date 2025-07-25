####################################################################################
# BSS COMMON
####################################################################################

variable "name_prefix" {
  description = "The account, environment etc"
  type        = string
}

variable "environment" {
  description = "The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD"
  type        = string
}

##################################################################################
# COGNITO
##################################################################################
variable "deletion_protection" {
  default = "INACTIVE"
}

variable "mfa_configuration" {
  default = "OFF"
}

variable "attribute_names" {
  type    = list(string)
  default = ["acr", "amr", "email", "idassurancelevel", "nhsid_nrbac_roles", "bss_username", "sid", "uid"]
}

variable "message_action" {
  default = "SUPPRESS"
}

variable "acr" {
  default = "AAL1_USERPASS"
}

variable "amr" {
  default = "USERPASS"
}

variable "user_email" {
  default = "nhsdigital.axe@nhs.net"
}

variable "user_password" {
  default = "changeme"
}

variable "csv_file" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "userdata" {
  description = "a csvdecode block that contains the userdata"
  type        = string
}
