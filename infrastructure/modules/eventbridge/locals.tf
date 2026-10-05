locals {
  # allow bus name to be overridden without touching tags
  bus_name = (
    # `module.this.id` is `""` (an error) when `module.this.enabled` is false
    # `coalesce()` errors if all arguments are null
    module.this.enabled
    ? coalesce(
      var.bus_name,
      module.this.enabled ? module.this.id : null,
    )
    : null
  )

  # The community module otherwise names the role after the bus, giving "default" on the default bus.
  role_name = module.this.enabled ? coalesce(var.role_name, module.this.id) : null

  # Same default as the iam and ecs-service wrappers, e.g. "/bcss/bcss/test/".
  default_iam_path = format(
    "/%s/",
    join("/", compact([module.this.service, module.this.project, module.this.environment]))
  )
  role_path   = coalesce(var.role_path, local.default_iam_path)
  policy_path = coalesce(var.policy_path, local.default_iam_path)

  # log delivery names must be unique per AWS account
  # provide a default name based on the module ID
  log_delivery = {
    for k, v in var.log_delivery : k => merge(
      {
        name = "${module.this.id}-${k}"
      },
      { for attribute, value in v : attribute => value if value != null }
    )
  }

  # schedule group names must be unique per AWS account and region
  # prefix provided names with the module ID to ensure uniqueness
  # validation prevents explicitly setting `name` or `name_prefix`
  schedule_groups = {
    for k, v in var.schedule_groups : k => (
      merge(v, { name = "${module.this.id}-${k}" })
    )
  }

  # if a schedule gives a group_name, fix it to match the corresponding
  # name in schedule_groups
  # schedule names follow the context naming convention, so prefix keys with
  # the module ID; a group_name key is resolved to the prefixed group name
  schedules = {
    for k, v in var.schedules : "${module.this.id}-${k}" => (
      try(local.schedule_groups[v.group_name], null) != null # either property could be absent
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
}
