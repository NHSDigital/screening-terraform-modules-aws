################################################################
# SES-specific inputs.
#
# Naming, tagging, and the master `enabled` switch come from
# context.tf via `module.this`.
#
# Inputs NOT exposed here (opinionated defaults hardcoded in main.tf):
#   - iam_create_access_key        → always false (credentials must not be stored in state)
#   - iam_create_ses_smtp_password → always false (credentials must not be stored in state)
#   - ses_group_name               → derived from module.this.id via locals.tf
################################################################

################################################################
# Domain identity
################################################################

variable "domain" {
  type        = string
  description = "The domain to create the SES identity for, e.g. \"example.nhs.uk\"."

  validation {
    condition     = can(regex("^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9])\\.)+[A-Za-z]{2,63}$", var.domain))
    error_message = "domain must be a valid fully-qualified domain name, e.g. \"example.nhs.uk\"."
  }
}

variable "zone_id" {
  type        = string
  default     = ""
  description = "Route53 parent zone ID. When provided, the module creates Route53 DNS records for domain verification, DKIM, SPF, and the custom MAIL FROM MX record. Leave empty to manage DNS records outside Terraform."
}

################################################################
# DNS verification and DKIM
################################################################

variable "verify_domain" {
  type        = bool
  default     = false
  description = "When true, creates a Route53 TXT record for SES domain ownership verification. Requires zone_id to be set."
}

variable "verify_dkim" {
  type        = bool
  default     = false
  description = "When true, creates Route53 CNAME records for DKIM signing verification. Requires zone_id to be set."
}

variable "create_spf_record" {
  type        = bool
  default     = false
  description = "When true, creates an SPF TXT record in Route53 for the domain. Requires zone_id to be set."
}

################################################################
# Custom MAIL FROM domain
################################################################

variable "custom_from_subdomain" {
  type        = list(string)
  default     = []
  description = "List of subdomains to use as the MAIL FROM (return-path) address. For example, [\"mail\"] sets the MAIL FROM domain to mail.<domain>. Required for DMARC alignment when verify_dkim is true."
}

variable "custom_from_dns_record_enabled" {
  type        = bool
  default     = false
  description = "When true, creates a Route53 MX record for the custom MAIL FROM subdomain. Only takes effect when custom_from_subdomain is non-empty. Requires zone_id to be set."
}

variable "custom_from_behavior_on_mx_failure" {
  type        = string
  default     = "UseDefaultValue"
  description = "The behaviour when the MX record for the custom MAIL FROM domain cannot be found. Valid values: UseDefaultValue (fall back to amazonses.com), RejectMessage (reject the outbound email)."

  validation {
    condition     = contains(["UseDefaultValue", "RejectMessage"], var.custom_from_behavior_on_mx_failure)
    error_message = "custom_from_behavior_on_mx_failure must be either \"UseDefaultValue\" or \"RejectMessage\"."
  }
}

################################################################
# IAM — sending identity (opt-in; off by default)
################################################################

variable "ses_user_enabled" {
  type        = bool
  default     = false
  description = "When true, creates an IAM user with permission to send emails via SES. Access key and SMTP password are never stored in Terraform state — distribute credentials out-of-band."
}

variable "ses_group_enabled" {
  type        = bool
  default     = false
  description = "When true, creates an IAM group with permission to send emails via SES. The group name is derived from context labels via module.this.id."
}

variable "ses_group_path" {
  type        = string
  default     = "/"
  description = "The IAM path for the SES IAM group."
}

variable "iam_permissions" {
  type        = list(string)
  default     = ["ses:SendRawEmail"]
  description = "List of IAM action strings granted to the SES IAM user or group."
}

variable "iam_allowed_resources" {
  type        = list(string)
  default     = []
  description = "List of resource ARNs that the IAM permissions apply to. Wildcards are accepted. When empty, the policy applies to all resources (`\"*\"`)."
}
