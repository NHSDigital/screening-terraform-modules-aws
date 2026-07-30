################################################################
# IAM Module
#
# Thin wrapper around the community
# `terraform-aws-modules/iam/aws` submodules:
#   - `iam-policy` — one per entry in `var.policies`
#   - `iam-role`   — one per entry in `var.roles`
#
# The upstream module has no root configuration (only submodules),
# so this wrapper invokes the relevant submodules
################################################################

################################################################
# Per-policy and per-role label modules
#
# Used to derive a stable, context-aware name and tag set for
# every policy/role produced by this wrapper.
################################################################

module "policy_label" {
  source   = "../tags"
  for_each = var.policies

  context    = module.this.context
  attributes = concat(module.this.attributes, ["policy", each.key])
}

module "role_label" {
  source   = "../tags"
  for_each = var.roles

  context    = module.this.context
  attributes = concat(module.this.attributes, ["role", each.key])
}

################################################################
# Customer-managed policies (upstream `iam-policy` submodule)
################################################################

module "policies" {
  source   = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version  = "6.6.1"
  for_each = module.this.enabled ? var.policies : {}

  name        = module.policy_label[each.key].id
  path        = each.value.path != null ? each.value.path : local.iam_path
  description = each.value.description
  policy      = each.value.policy

  tags = module.policy_label[each.key].tags
}

################################################################
# IAM roles (upstream `iam-role` submodule)
#
# `policy_arns` (externally-managed) and `policy_keys` (policies
# created above in this same invocation) are merged into the
# single `policies = { name => arn }` map the submodule expects.
#
# `inline_policies` is forwarded via `source_inline_policy_documents`
# so all statements are merged into one inline policy per role.
################################################################

module "roles" {
  source   = "terraform-aws-modules/iam/aws//modules/iam-role"
  version  = "6.6.1"
  for_each = module.this.enabled ? var.roles : {}

  name            = module.role_label[each.key].id
  use_name_prefix = false
  path            = each.value.path != null ? each.value.path : local.iam_path
  description     = each.value.description

  max_session_duration = each.value.max_session_duration
  permissions_boundary = each.value.permissions_boundary

  # Caller-supplied trust policy JSON is merged in as a source document.
  source_trust_policy_documents = [each.value.assume_role_policy]

  policies = local.role_policies[each.key]

  create_inline_policy           = length(each.value.inline_policies) > 0
  source_inline_policy_documents = values(each.value.inline_policies)

  tags = module.role_label[each.key].tags
}
