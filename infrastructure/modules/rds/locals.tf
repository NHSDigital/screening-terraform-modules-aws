locals {
  # Prefer explicit caller names when provided, otherwise derive from context labels.
  # Upstream coalesces identifier into sub-resource names even when create = false.
  rds_identifier = module.this.enabled ? coalesce(var.identifier, module.this.id) : "disabled"
}
