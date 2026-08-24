locals {
  table_name = coalesce(var.table_name, module.this.id)
}
