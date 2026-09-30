locals {
  # When delimiter is "/", prepend "/" to ensure path-style parameter names (AWS SSM standard)
  parameter_name = var.parameter_name != null ? var.parameter_name : (module.ssm_param_label.delimiter == "/" ? format("/%s", module.ssm_param_label.id) : module.ssm_param_label.id)

  secure_type = var.type == "SecureString"

  # StringList values are JSON-encoded, matching the ssm-parameter module behaviour
  plain_value = local.secure_type ? null : (var.type == "StringList" && length(var.values) > 0 ? jsonencode(var.values) : var.value)

  # String/StringList values are not secrets by definition; SecureString never populates insecure_value
  insecure_value = one(compact([
    try(nonsensitive(aws_ssm_parameter.this[0].insecure_value), null),
    try(nonsensitive(aws_ssm_parameter.ignore_value[0].insecure_value), null),
  ]))
}
