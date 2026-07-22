locals {
  # Parameter name: use custom override if provided, otherwise derive from context
  # When delimiter is "/", prepend "/" to ensure path-style parameter names (AWS SSM standard)
  parameter_name = var.parameter_name != null ? var.parameter_name : (module.ssm_param_label.delimiter == "/" ? format("/%s", module.ssm_param_label.id) : module.ssm_param_label.id)
}
