################################################################
# Application / Network Load Balancer
#
# Thin NHS wrapper around the community ALB module that enforces
# the screening platform's baseline controls:
#
#   * Deletion protection: enabled by default; set enable_deletion_protection = false for non-prod
#   * Invalid header fields: always dropped (ALB only)
#   * HTTP→HTTPS redirect: automatic on port 80 for ALBs (disable with enable_http_https_redirect = false)
#   * Naming:  derived from context labels via module.this.id
#   * Tagging: all NHS-required tags applied automatically
#   * Enabled flag: create = module.this.enabled
#
# Inputs intentionally NOT exposed (hardcoded below):
#   - drop_invalid_header_fields → always true (ALB); null (NLB)
################################################################

locals {
  # Inject an HTTP → HTTPS redirect listener on port 80 when enabled (ALB only).
  # Callers can override by providing their own "http-redirect" key in var.listeners.
  http_redirect_listener = var.enable_http_https_redirect && var.load_balancer_type == "application" ? {
    http-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  } : {}

  effective_listeners = merge(local.http_redirect_listener, var.listeners)
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "10.5.0"

  create = module.this.enabled

  name               = module.this.id
  load_balancer_type = var.load_balancer_type
  internal           = var.internal
  vpc_id             = var.vpc_id
  subnets            = var.subnets

  # ----------------------------------------------------------------
  # Security baseline — drop_invalid_header_fields is hardcoded.
  # enable_deletion_protection defaults to true; callers may set it to
  # false for non-production environments.
  # drop_invalid_header_fields is ALB-only; pass null for NLB so
  # the upstream module does not error.
  # ----------------------------------------------------------------
  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = var.load_balancer_type == "application" ? true : null

  # ----------------------------------------------------------------
  # Security group rules — caller-supplied so both ALB (HTTP+HTTPS)
  # and NLB (TCP) patterns are supported.
  # ----------------------------------------------------------------
  security_group_ingress_rules = var.security_group_ingress_rules
  security_group_egress_rules  = var.security_group_egress_rules

  # ----------------------------------------------------------------
  # Access logging to a caller-supplied S3 bucket.
  # ----------------------------------------------------------------
  access_logs = var.access_logs

  # ----------------------------------------------------------------
  # Listeners — merged with the automatic HTTP→HTTPS redirect (ALB only).
  # Target groups are passed through as-is.
  # ----------------------------------------------------------------
  listeners     = local.effective_listeners
  target_groups = var.target_groups

  # ----------------------------------------------------------------
  # WAF association — optional, ALB only.
  # ----------------------------------------------------------------
  associate_web_acl = var.web_acl_arn != null
  web_acl_arn       = var.web_acl_arn

  # ----------------------------------------------------------------
  # Tags — automatically populated from context.
  # ----------------------------------------------------------------
  tags = module.this.tags
}
