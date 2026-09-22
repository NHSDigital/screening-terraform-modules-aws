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

  # API destination names must be unique per AWS account and region.
  # We prefix provided names with the module ID to ensure uniqueness.
  # Furthermore, `connection_name`s must match up with the keys of
  # `connections`.
  api_destinations = {
    for k, v in var.api_destinations : "${module.this.id}-${k}" => merge(
      v,
      can(v, "connection_name")
      && v.connection_name != null
      && contains(keys(var.connections), v.connection_name)
      ? { connection_name = "${module.this.id}-${v.connection_name}" }
      : {}
    )
  }

  # schedule group names must be unique per AWS account and region
  # prefix provided names with the module ID to ensure uniqueness
  # disallow explicitly setting `name` or `name_prefix`
  schedule_groups = {
    for k, v in var.schedule_groups : k => (
      merge(v, { name = "${module.this.id}-${k}" })
    )
  }

  # if a schedule gives a group_name, fix it to match the corresponding
  # name in schedule_groups
  schedules = {
    for k, v in var.schedules : k => (
      contains(keys(v), "group_name") && local.schedule_groups[v.group_name] != null
      ? merge(
        v,
        {
          group_name = local.schedule_groups[v.group_name].name
        }
      )
      : v
    )
  }

  # pipe names must be unique per AWS account and region
  # prefix keys with the module ID to ensure uniqueness
  pipes = {
    for k, v in var.pipes : "${module.this.id}-${k}" => {
      for attribute, value in v : attribute => value if value != null
    }
  }
  # DAVEH: Pipe → API destination enrichment
  # The wrapper prefixes API-destination keys, but leaves pipes[*].enrichment unchanged.

  # DAVEH: EventBridge target → API destination
  # The wrapper prefixes api_destinations keys in locals.tf:23-26, but
  # leaves targets[*].destination unchanged.
}
