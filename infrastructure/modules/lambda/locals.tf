locals {
  # Use the caller-supplied secret name if provided; otherwise fall back
  # to the auto-generated context ID. The caller controls the generated
  # name by setting context labels: service, environment, stack, name, etc.
  function_name = var.function_name != null ? var.function_name : module.this.id
}
