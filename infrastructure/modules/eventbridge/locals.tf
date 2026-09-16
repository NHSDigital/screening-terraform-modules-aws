locals {
  # allow bus name to be overridden without touching tags
  bus_name = coalesce(var.bus_name, module.this.id)
}
