resource "terraform_data" "validations" {
  count = module.this.enabled ? 1 : 0

  lifecycle {
    precondition {
      condition = anytrue([
        !var.create_role,
        !var.attach_sns_policy,
        length(var.sns_kms_arns) > 0,
      ])

      error_message = "attach_sns_policy requires at least one specific sns_kms_arns entry."
    }

    precondition {
      condition = anytrue([
        !var.create_bus,
        try(trimspace(var.kms_key_identifier) != "", false),
      ])

      error_message = "kms_key_identifier must not be empty when creating the bus"
    }
  }
}
