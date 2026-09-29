locals {
  table_name = module.this.enabled ? coalesce(var.table_name, module.this.id) : null
}
