locals {
  # Enforce DNS validation when caller does not explicitly set the method.
  validation_method = coalesce(var.validation_method, "DNS")

  create_route53_records      = true
  create_route53_records_only = false
}
