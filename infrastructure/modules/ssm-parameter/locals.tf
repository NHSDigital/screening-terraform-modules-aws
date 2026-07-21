locals {
  # Parameter name: use custom override if provided, otherwise derive from context
  parameter_name = var.parameter_name != null ? var.parameter_name : module.ssm_param_label.id
}
