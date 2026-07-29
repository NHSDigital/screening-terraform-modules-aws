locals {
  # Log group name: use custom name if provided, otherwise derive from context
  # When delimiter is "/", prepend "/" to ensure path-style log group names
  log_group_name = var.log_group_name != null ? var.log_group_name : (module.log_group_label.delimiter == "/" ? format("/%s", module.log_group_label.id) : module.log_group_label.id)
}
