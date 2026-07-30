locals {
  # Secret name: use custom override if provided, otherwise derive from context
  # labels via module.secret_label.id (e.g. "bcss-screening-test-db-credentials")
  # When delimiter is "/", prepend "/" to ensure path-style secrets names
  secret_name = var.secret_name != null ? var.secret_name : (module.secret_label.delimiter == "/" ? format("/%s", module.secret_label.id) : module.secret_label.id)
}
