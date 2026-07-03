locals {
  # Prefer explicit caller names when provided, otherwise derive from context labels.
  rds_identifier = coalesce(var.identifier, module.this.id)
}
