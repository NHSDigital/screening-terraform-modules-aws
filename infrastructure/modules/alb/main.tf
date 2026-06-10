################################################################
# Application / Network Load Balancer
#
# Thin NHS wrapper around the community ALB module that enforces
# the screening platform's baseline controls:
#
#   * Deletion protection: always enabled
#   * Invalid header fields: always dropped (ALB only)
#   * Naming:  derived from context labels via module.this.id
#   * Tagging: all NHS-required tags applied automatically
#   * Enabled flag: create = module.this.enabled
#
# Inputs intentionally NOT exposed (hardcoded below):
#   - enable_deletion_protection → always true
#   - drop_invalid_header_fields → always true (ALB); null (NLB)
################################################################

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
  # Security baseline — hardcoded, callers cannot override.
  # drop_invalid_header_fields is ALB-only; pass null for NLB so
  # the upstream module does not error.
  # ----------------------------------------------------------------
  enable_deletion_protection = true
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
  # Listeners and target groups — passed through as-is.
  # Callers define the full listener/target group configuration
  # including SSL policies, certificates, health checks, etc.
  # ----------------------------------------------------------------
  listeners     = var.listeners
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
