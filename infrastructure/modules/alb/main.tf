################################################################
# Application / Network Load Balancer
#
# Thin NHS wrapper around the community ALB module that enforces
# the screening platform's baseline controls:
#
#   * Deletion protection: enabled by default; set enable_deletion_protection = false for non-prod
#   * Invalid header fields: always dropped (ALB only)
#   * HTTP→HTTPS redirect: automatic on port 80 for ALBs (disable with enable_http_https_redirect = false)
#   * Naming: derived from context labels via module.this.id
#   * Tagging: all NHS-required tags applied automatically
#   * Enabled flag: create = module.this.enabled
#   * Security groups: REQUIRED caller-supplied list (not created by this module)
#   * Desync mitigation: ALB-only, configurable for HTTP desync attack protection
#   * HTTP/2: ALB-only, enabled by default
#   * XFF header processing: ALB-only, controlled for request header validation
#
# Inputs intentionally NOT exposed (hardcoded below):
#   - create_security_group → always false (use var.security_groups)
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
  # Security baseline — drop_invalid_header_fields is hardcoded.
  # enable_deletion_protection defaults to true; callers may set it to
  # false for non-production environments.
  # drop_invalid_header_fields is ALB-only; pass null for NLB so
  # the upstream module does not error.
  # ----------------------------------------------------------------
  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = var.load_balancer_type == "application" ? true : null

  # ----------------------------------------------------------------
  # Security groups — REQUIRED caller-supplied list.
  # create_security_group is hardcoded false to enforce that callers
  # pre-create security groups with explicit ingress/egress rules.
  # ----------------------------------------------------------------
  create_security_group = false
  security_groups       = var.security_groups

  # ----------------------------------------------------------------
  # ALB-specific security settings.
  # Desync mitigation: prevents HTTP request smuggling attacks.
  # HTTP/2: improves connection efficiency (ALB only).
  # XFF header processing: validates X-Forwarded-For headers (ALB only).
  # Idle timeout: connection timeout in seconds (ALB/NLB).
  # Preserve host header: maintains original Host header from client (ALB only).
  # Cross-zone load balancing: distribute traffic across AZs.
  # ----------------------------------------------------------------
  desync_mitigation_mode           = var.load_balancer_type == "application" ? var.desync_mitigation_mode : null
  enable_http2                     = var.load_balancer_type == "application" ? var.enable_http2 : null
  xff_header_processing_mode       = var.load_balancer_type == "application" ? var.xff_header_processing_mode : null
  idle_timeout                     = var.idle_timeout
  preserve_host_header             = var.load_balancer_type == "application" ? var.preserve_host_header : null
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

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
