################################################################
# License Manager
#
# Creates a self-managed AWS License Manager license configuration
# (vCPU / Core / Socket / Instance counted), optionally enforces a
# hard limit, and optionally associates the configuration with one
# or more resource ARNs (e.g. AMIs, EC2 instances, hosts).
#
# Naming and tagging are derived from `context.tf` via
# `module.this` so this module composes consistently across
# screening service stacks and accounts.
################################################################

locals {
  # Allow callers to override the generated name. Fall back to the
  # context-derived id so naming stays consistent with sibling
  # modules.
  license_configuration_name = coalesce(var.name_override, module.this.id)
}

################################################################
# License configuration
################################################################

resource "aws_licensemanager_license_configuration" "this" {
  count = module.this.enabled ? 1 : 0

  name                     = local.license_configuration_name
  description              = var.description
  license_count            = var.license_count
  license_count_hard_limit = var.license_count_hard_limit
  license_counting_type    = var.license_counting_type
  license_rules            = var.license_rules

  tags = module.this.tags

  lifecycle {
    precondition {
      condition     = local.license_configuration_name != null && local.license_configuration_name != ""
      error_message = "License configuration name resolved to an empty string. Set var.name (via context) or var.name_override."
    }
  }
}

################################################################
# Associations (e.g. AMIs, EC2 instances, hosts)
#
# The for_each key is a stable, caller-supplied identifier so
# resources can be added/removed without forcing other entries to
# be re-created.
################################################################

resource "aws_licensemanager_association" "this" {
  for_each = module.this.enabled ? var.associated_resource_arns : {}

  license_configuration_arn = aws_licensemanager_license_configuration.this[0].arn
  resource_arn              = each.value
}
