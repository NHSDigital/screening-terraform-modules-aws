locals {
  default_path = format(
    "/%s/%s/%s",
    module.this.service,
    module.this.project,
    module.this.environment
  )
  path = var.path != null ? var.path : local.default_path
  name = "${trimsuffix(local.path, "/")}/${module.this.id}"
}
