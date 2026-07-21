################################################################
# Cross-variable validation constraints for ALB/NLB.
#
# These preconditions catch configuration errors that span multiple
# variables and would otherwise surface only at apply time or in
# unexpected runtime behaviour.
################################################################

resource "terraform_data" "validation" {
  lifecycle {
    precondition {
      condition     = var.internal || var.access_logs != null
      error_message = "Internet-facing ALB/NLB should have access_logs enabled for security compliance, auditing, and troubleshooting. Set access_logs block or set internal = true."
    }

    precondition {
      condition     = length(var.security_groups) > 0
      error_message = "var.security_groups must contain at least one security group ID. Callers must pre-create and supply security groups explicitly."
    }

    precondition {
      condition     = !var.enable_http2 || var.load_balancer_type == "application"
      error_message = "var.enable_http2 is only valid for ALB (load_balancer_type = 'application'). Set enable_http2 = false for NLB or change load_balancer_type to 'application'."
    }

    precondition {
      condition     = var.desync_mitigation_mode == null || var.load_balancer_type == "application"
      error_message = "var.desync_mitigation_mode is only valid for ALB (load_balancer_type = 'application'). Omit this variable or change load_balancer_type to 'application'."
    }

    precondition {
      condition     = var.preserve_host_header == false || var.load_balancer_type == "application"
      error_message = "var.preserve_host_header is only valid for ALB (load_balancer_type = 'application'). Set preserve_host_header = false for NLB or change load_balancer_type to 'application'."
    }

    precondition {
      condition     = var.xff_header_processing_mode == "append" || var.load_balancer_type == "application"
      error_message = "var.xff_header_processing_mode is only valid for ALB (load_balancer_type = 'application'). Use default (append) or change load_balancer_type to 'application'."
    }
  }
}
