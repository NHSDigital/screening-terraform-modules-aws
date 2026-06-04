# DAVEH

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 6.3.0"

  acm_certificate_domain_validation_options = DAVEH
  certificate_transparency_logging_preference = DAVEH
  create_certificate = module.this.enabled
  create_route53_records = DAVEH
  create_route53_records_only = DAVEH
  distinct_domain_names = DAVEH
  dns_ttl = DAVEH
  domain_name = DAVEH
  export = DAVEH
  key_algorithm = DAVEH
  private_authority_arn = DAVEH
  region = module.this.region
  subject_alternative_names = DAVEH
  tags = module.this.tags
  validate_certificate = DAVEH
  validation_allow_overwrite_records = DAVEH
  validation_method = DAVEH
  validation_option = DAVEH
  validation_record_fqdns = DAVEH
  validation_timeout = DAVEH
  wait_for_validation = DAVEH
  zone_id = DAVEH
  zones = DAVEH
}
