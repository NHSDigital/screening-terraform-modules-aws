################################################################
# IAM Module
#
# Creates a configurable set of IAM customer-managed policies
# (primary use case: attached to AWS SSO permission sets via
# `customer_managed_policy_references`), plus an optional set of
# IAM roles with policy attachments.
#
# Naming and tagging come from `context.tf` / `module.this`.
################################################################

locals {
  # Default IAM path falls back to a context-derived value so policies/roles
  # are grouped under a predictable namespace, e.g. "/bcss/screening/".
  default_iam_path = format(
    "/%s/",
    join("/", compact([module.this.service, module.this.project]))
  )
  iam_path = var.path != null ? var.path : local.default_iam_path
}

################################################################
# Customer-managed policies
#
# Each entry in `var.policies` becomes one aws_iam_policy. The
# policy document is taken verbatim from the entry's `policy`
# attribute (caller is expected to render it via
# `aws_iam_policy_document` data sources or `jsonencode`).
################################################################

resource "aws_iam_policy" "this" {
  for_each = module.this.enabled ? var.policies : {}

  name        = module.policy_label[each.key].id
  path        = each.value.path != null ? each.value.path : local.iam_path
  description = each.value.description
  policy      = each.value.policy

  tags = module.policy_label[each.key].tags
}

module "policy_label" {
  source   = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/tags?ref=feature/BCSS-23189-add-new-modules-to-suppport-bcss"
  for_each = var.policies

  context    = module.this.context
  attributes = concat(module.this.attributes, ["policy", each.key])
}

################################################################
# IAM Roles
#
# Each entry in `var.roles` becomes one aws_iam_role. The trust
# policy is taken from `assume_role_policy` (rendered JSON). The
# role is wired to:
#   - `policy_arns`         — attaches existing/managed policies
#   - `policy_keys`         — attaches policies created above by key
#   - `inline_policies`     — map of name -> JSON to attach inline
################################################################

resource "aws_iam_role" "this" {
  for_each = module.this.enabled ? var.roles : {}

  name                 = module.role_label[each.key].id
  path                 = each.value.path != null ? each.value.path : local.iam_path
  description          = each.value.description
  assume_role_policy   = each.value.assume_role_policy
  max_session_duration = each.value.max_session_duration
  permissions_boundary = each.value.permissions_boundary

  tags = module.role_label[each.key].tags
}

module "role_label" {
  source   = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/tags?ref=feature/BCSS-23189-add-new-modules-to-suppport-bcss"
  for_each = var.roles

  context    = module.this.context
  attributes = concat(module.this.attributes, ["role", each.key])
}

# Flatten role -> external policy ARNs into one attachment per pair.
locals {
  role_external_policy_attachments = module.this.enabled ? merge([
    for role_key, role in var.roles : {
      for policy_arn in role.policy_arns :
      "${role_key}::${policy_arn}" => {
        role_key   = role_key
        policy_arn = policy_arn
      }
    }
  ]...) : {}

  # Flatten role -> policy_keys (referring to entries in var.policies).
  role_internal_policy_attachments = module.this.enabled ? merge([
    for role_key, role in var.roles : {
      for policy_key in role.policy_keys :
      "${role_key}::${policy_key}" => {
        role_key   = role_key
        policy_key = policy_key
      }
    }
  ]...) : {}

  # Flatten role -> inline policies.
  role_inline_policies = module.this.enabled ? merge([
    for role_key, role in var.roles : {
      for name, doc in role.inline_policies :
      "${role_key}::${name}" => {
        role_key = role_key
        name     = name
        policy   = doc
      }
    }
  ]...) : {}
}

resource "aws_iam_role_policy_attachment" "external" {
  for_each = local.role_external_policy_attachments

  role       = aws_iam_role.this[each.value.role_key].name
  policy_arn = each.value.policy_arn
}

resource "aws_iam_role_policy_attachment" "internal" {
  for_each = local.role_internal_policy_attachments

  role       = aws_iam_role.this[each.value.role_key].name
  policy_arn = aws_iam_policy.this[each.value.policy_key].arn
}

resource "aws_iam_role_policy" "inline" {
  for_each = local.role_inline_policies

  name   = each.value.name
  role   = aws_iam_role.this[each.value.role_key].id
  policy = each.value.policy
}
