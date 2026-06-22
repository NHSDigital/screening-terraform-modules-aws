locals {
  # Default IAM path falls back to a context-derived value so policies/roles
  # are grouped under a predictable namespace, e.g. "/bcss/screening/".
  default_iam_path = format(
    "/%s/",
    join("/", compact([module.this.service, module.this.project, module.this.environment]))
  )
  iam_path = var.path != null ? var.path : local.default_iam_path

  # role_key -> { static_name => policy_arn } for attached policies.
  role_policies = {
    for role_key, role in var.roles : role_key => merge(
      { for idx, arn in role.policy_arns : "external-${idx}" => arn },
      { for k in role.policy_keys : k => module.policies[k].arn }
    )
  }
}
