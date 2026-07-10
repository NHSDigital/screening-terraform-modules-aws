locals {
  # Default IAM path falls back to a context-derived value so policies/roles
  # are grouped under a predictable namespace, e.g. "/bcss/screening/".
  default_iam_path = format(
    "/%s/",
    join("/", compact([module.this.service, module.this.project, module.this.environment]))
  )
  iam_path = var.iam_path != null ? var.iam_path : local.default_iam_path

  # Service name is derived from context. The community module receives
  # module.this.name directly so that context-driven label ordering is
  # preserved without an intermediate local in the common case.
  service_name = var.service_name != null ? var.service_name : module.this.name
}
