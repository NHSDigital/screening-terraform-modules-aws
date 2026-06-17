variable "validation_method" {
  description = "Which method to use for validation. Only DNS is valid. This parameter must not be set for certificates that were imported into ACM and then into Terraform."
  type        = string
  default     = null

  validation {
    condition     = var.validation_method == null || var.validation_method == "DNS"
    error_message = "validation_method must be null or \"DNS\"."
  }
}

variable "validation_allow_overwrite_records" {
  description = "Whether to allow overwrite of Route53 records"
  type        = bool
  default     = true
}

variable "validation_timeout" {
  description = "Define maximum timeout to wait for the validation to complete"
  type        = string
  default     = null
}

variable "wait_for_validation" {
  description = "Whether to wait for the validation to complete"
  type        = bool
  default     = true
}

variable "validation_record_fqdns" {
  description = "When DNS validation records are managed externally, provide the FQDNs for certificate validation."
  type        = list(string)
  default     = []
}

variable "zone_id" {
  description = "The ID of the hosted zone to contain this record, for validating via Route53."
  type        = string
}

variable "zones" {
  description = "Map containing the Route53 Zone IDs for additional domains."
  type        = map(string)
  default     = {}
}

variable "create_route53_records_only" {
  description = "When true, creates only Route53 validation records for a certificate created outside this module."
  type        = bool
  default     = false

  validation {
    condition     = !var.create_route53_records_only || (length(var.distinct_domain_names) > 0 && try(length(var.acm_certificate_domain_validation_options), 0) > 0)
    error_message = "When create_route53_records_only is true, distinct_domain_names and acm_certificate_domain_validation_options must both be provided."
  }
}

variable "acm_certificate_domain_validation_options" {
  description = "Domain validation options from an externally created ACM certificate, used with create_route53_records_only."
  type        = any
  default     = {}
}

variable "distinct_domain_names" {
  description = "Distinct domain names matching the external certificate validation options, used with create_route53_records_only."
  type        = list(string)
  default     = []
}

variable "domain_name" {
  description = "A domain name for which the certificate should be issued"
  type        = string
  default     = ""
}

variable "subject_alternative_names" {
  description = "Additional domain names for which the certificate should be issued."
  type        = list(string)
  default     = []
}

variable "dns_ttl" {
  description = "The TTL of DNS recursive resolvers to cache information about this record."
  type        = number
  default     = 60
}

variable "key_algorithm" {
  description = "Specifies the algorithm of the public and private key pair that your Amazon issued certificate uses to encrypt data"
  type        = string
  default     = null
}

variable "certificate_transparency_logging_preference" {
  description = "Whether certificate transparency logging is enabled for issued certificates."
  type        = bool
  default     = true
}

variable "private_authority_arn" {
  description = "Private Certificate Authority ARN for issuing private certificates"
  type        = string
  default     = null
}
