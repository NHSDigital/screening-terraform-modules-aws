# DAVEH

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

variable "zone_id" {
  description = "The ID of the hosted zone to contain this record, for validating via Route53."
  type        = string
}

variable "zones" {
  description = "Map containing the Route53 Zone IDs for additional domains."
  type        = map(string)
  default     = {}
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
