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

  # API destination names must be unique per AWS account and region
  # prefix provided names with the module ID to ensure uniqueness
  api_destinations = {
    for k, v in var.api_destinations : "${module.this.id}-${k}" => v
  }

  # schedule group names must be unique per AWS account and region
  # respect `name` and `name_prefix` if given
  # otherwise include module ID and key in `name_prefix`
  schedule_groups = {
    for k, v in var.schedule_groups : k => (
      contains(keys(v), "name") || contains(keys(v), "name_prefix")
      ? v
      : merge(
        {
          name_prefix = "${module.this.id}-${k}"
        },
        v
      )
    )
  }

  # pipe names must be unique per AWS account and region
  # prefix keys with the module ID to ensure uniqueness
  pipes = {
    for k, v in var.pipes : "${module.this.id}-${k}" => {
      for attribute, value in v : attribute => value if value != null
    }
  }
}
