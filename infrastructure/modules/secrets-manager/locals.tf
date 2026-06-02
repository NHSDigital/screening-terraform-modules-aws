locals {
  # Use the caller-supplied secret name if provided; otherwise fall back
  # to the auto-generated context ID. The caller controls the generated
  # name by setting context labels: service, environment, stack, name, etc.
  secret_name = var.secret_name != null ? var.secret_name : module.this.id
}
