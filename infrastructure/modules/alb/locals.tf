locals {
  is_alb = var.load_balancer_type == "application"
  has_subnets        = var.subnets != null && length(var.subnets) > 0
  has_subnet_mapping = var.subnet_mapping != null && length(var.subnet_mapping) > 0

  # Keep wrapper behaviour flexible: if both are provided, prefer subnet_mapping
  # and suppress subnets to satisfy AWS one-of semantics.
  effective_subnet_mapping = local.has_subnet_mapping ? var.subnet_mapping : null
  effective_subnets        = local.has_subnet_mapping ? null : (local.has_subnets ? var.subnets : null)

  # ALB-only derived defaults. NLB keeps null for these upstream inputs.
  effective_drop_invalid_header_fields = local.is_alb ? true : null
  effective_desync_mitigation_mode     = local.is_alb ? coalesce(var.desync_mitigation_mode, "defensive") : null
  effective_enable_http2               = local.is_alb ? coalesce(var.enable_http2, true) : null
  effective_xff_header_processing_mode = local.is_alb ? coalesce(var.xff_header_processing_mode, "append") : null
  effective_preserve_host_header       = local.is_alb ? coalesce(var.preserve_host_header, false) : null

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
