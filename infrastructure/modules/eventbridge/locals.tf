locals {
  # allow bus name to be overridden without touching tags
  bus_name = coalesce(var.bus_name, module.this.id)

  # log delivery names must be unique per AWS account
  # provide a default name based on the module ID
  log_delivery = {
    for k, v in var.log_delivery : k => merge(
      {
        name = "${module.this.id}-${k}"
      },
      v
    )
  }

  # connection names must be unique per AWS account and region
  # prefix provided names with the module ID to ensure uniqueness
  connections = {
    for k, v in var.connections : "${module.this.id}-${k}" => v
  }
}
