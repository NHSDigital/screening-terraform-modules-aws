################################################################
# Input validation
#
# Validates cross-variable constraints that cannot be expressed
# through individual variable validation blocks:
#
#   * verify_domain, verify_dkim, and create_spf_record all require
#     zone_id to be set (Route53 records cannot be created without it)
#   * custom_from_dns_record_enabled requires zone_id when
#     custom_from_subdomain is non-empty
################################################################

resource "terraform_data" "validations" {
  count = module.this.enabled ? 1 : 0

  lifecycle {
    precondition {
      condition     = !var.verify_domain || var.zone_id != ""
      error_message = "verify_domain requires zone_id to be set."
    }
    precondition {
      condition     = !var.verify_dkim || var.zone_id != ""
      error_message = "verify_dkim requires zone_id to be set."
    }
    precondition {
      condition     = !var.create_spf_record || var.zone_id != ""
      error_message = "create_spf_record requires zone_id to be set."
    }
    precondition {
      condition     = !var.custom_from_dns_record_enabled || length(var.custom_from_subdomain) == 0 || var.zone_id != ""
      error_message = "custom_from_dns_record_enabled requires zone_id when custom_from_subdomain is non-empty."
    }
  }
}
