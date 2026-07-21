locals {
  # Log group name: use custom name if provided, otherwise derive from context
  log_group_name = var.log_group_name != null ? var.log_group_name : module.log_group_label.id
}
