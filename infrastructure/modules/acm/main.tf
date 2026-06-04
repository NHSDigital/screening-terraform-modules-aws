################################################################
# AWS Certificate Manager (ACM)
#
# A thin wrapper around the terraform-aws-modules/acm/aws module,
# enforcing the following opinions:
#
#   * new certificates are validated via DNS, specifically via Route53
#   * certificates cannot be exported
#
# Tagging is derived from context.tf via module.this.
################################################################

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 6.3.0"

  create_certificate   = module.this.enabled
  validate_certificate = module.this.enabled

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names

  key_algorithm         = var.key_algorithm
  private_authority_arn = var.private_authority_arn

  certificate_transparency_logging_preference = true
  export                                      = "DISABLED"

  # ----------------------------------------------------------------
  # Validation: only DNS is supported, unless you have imported the certificate
  # ----------------------------------------------------------------
  validation_method                  = var.validation_method
  validation_allow_overwrite_records = var.validation_allow_overwrite_records
  validation_timeout                 = var.validation_timeout
  wait_for_validation                = var.wait_for_validation
  zone_id                            = var.zone_id
  zones                              = var.zones
  create_route53_records             = true
  create_route53_records_only        = false
  dns_ttl                            = var.dns_ttl

  # ----------------------------------------------------------------
  region = module.this.region
  tags = module.this.tags
}
