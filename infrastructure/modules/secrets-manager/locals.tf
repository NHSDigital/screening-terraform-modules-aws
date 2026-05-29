locals {
  # Use the auto-generated context ID as the secret name.
  # The caller controls the name by setting context labels:
  # service, environment, stack, name, etc.
  secret_name = module.this.id
}
