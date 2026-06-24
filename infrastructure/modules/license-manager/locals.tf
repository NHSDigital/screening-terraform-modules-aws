locals {
  # Allow callers to override the generated name. Fall back to the
  # context-derived id so naming stays consistent with sibling
  # modules.
  license_configuration_name = coalesce(var.name_override, module.this.id)
}
