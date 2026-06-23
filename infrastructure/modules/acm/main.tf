################################################################
# AWS Certificate Manager (ACM)
#
# A thin wrapper around the terraform-aws-modules/acm/aws module,
# enforcing the following controls:
#
#   * new certificates are validated via DNS, specifically via Route53
#   * certificates cannot be exported
#
# Tagging is derived from context.tf via module.this.
################################################################

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "6.3.0"

  create_certificate   = local.create_certificate
  validate_certificate = local.validate_certificate

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names

  key_algorithm         = var.key_algorithm
  private_authority_arn = var.private_authority_arn

  certificate_transparency_logging_preference = var.certificate_transparency_logging_preference
  export                                      = "DISABLED"

  # ----------------------------------------------------------------
  # Validation: only DNS is supported, unless you have imported the certificate
  # ----------------------------------------------------------------
  validation_method                         = local.validation_method
  validation_allow_overwrite_records        = var.validation_allow_overwrite_records
  validation_timeout                        = var.validation_timeout
  wait_for_validation                       = var.wait_for_validation
  validation_record_fqdns                   = var.validation_record_fqdns
  zone_id                                   = var.zone_id
  zones                                     = var.zones
  create_route53_records                    = local.create_route53_records
  create_route53_records_only               = var.create_route53_records_only
  acm_certificate_domain_validation_options = var.acm_certificate_domain_validation_options
  distinct_domain_names                     = var.distinct_domain_names
  dns_ttl                                   = var.dns_ttl

  # ----------------------------------------------------------------
  region = module.this.region
  tags   = module.this.tags
}
