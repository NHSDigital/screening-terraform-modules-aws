module "eventbridge" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eventbridge.git?ref=f9934726324c988f823682884b4fa003586a7b6f" # v4.3.2

  # Using a separate EventBridge bus per workspace would remove collisions for resources scoped to a bus:
  #
  # - rules keys and rule names
  # - targets associated with those rules
  # - archives
  # - EventBridge permissions
  # - bus-specific log-delivery associations
  #
  # However, these remain account/region-wide and still need workspace-unique names:
  #
  # - IAM role role_name
  # - Generated IAM policy names
  # - EventBridge connections
  # - API destinations
  # - Scheduler schedule groups and schedules
  # - EventBridge Pipes
  # - Log-delivery source and destination names
  #
  # The bus itself also needs a workspace-unique bus_name.
  # DAVEH: rm above comment when actioned

  # DAVEH: add attributes
}
