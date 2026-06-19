locals {
  # Prefer explicit caller names when provided, otherwise derive from context labels.
  rds_identifier = coalesce(var.custom_name, var.identifier, module.this.id)
}
