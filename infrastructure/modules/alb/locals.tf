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
