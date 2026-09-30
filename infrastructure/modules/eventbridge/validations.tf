resource "terraform_data" "validations" {
  count = module.this.enabled ? 1 : 0

  lifecycle {
    precondition {
      condition     = !var.attach_sns_policy || length(var.sns_kms_arns) > 0
      error_message = "attach_sns_policy requires at least one specific sns_kms_arns entry."
    }
  }
}
