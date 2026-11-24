resource "terraform_data" "lb_log_delivery_encryption_exception" {
  count = var.allow_lb_log_delivery_without_encryption_headers ? 1 : 0

  lifecycle {
    precondition {
      condition     = module.this.enabled && var.attach_lb_log_delivery_policy && var.kms_master_key_arn == null && length(var.server_side_encryption_configuration) == 0
      error_message = "allow_lb_log_delivery_without_encryption_headers requires the ALB/NLB delivery policy and the default SSE-S3 encryption configuration."
    }
  }
}
