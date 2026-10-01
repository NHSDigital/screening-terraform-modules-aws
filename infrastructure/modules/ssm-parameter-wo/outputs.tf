output "insecure_value" {
  description = "Value of a `String`/`StringList` parameter. Always null for `SecureString`."
  value       = local.insecure_value
}

output "raw_value" {
  description = "Raw stored value of a `String`/`StringList` parameter. Always null for `SecureString`. Use `value` for the JSON-decoded value."
  value       = local.insecure_value
  sensitive   = true
}

output "secure_type" {
  description = "Whether the SSM parameter is a SecureString"
  value       = local.secure_type
}

output "secure_value" {
  description = "Always null: SecureString values are write-only and never read back into state."
  value       = null
  sensitive   = true
}

output "ssm_parameter_arn" {
  description = "The ARN of the parameter"
  value       = try(aws_ssm_parameter.this[0].arn, aws_ssm_parameter.ignore_value[0].arn, null)
}

output "ssm_parameter_name" {
  description = "Name of the parameter"
  value       = try(aws_ssm_parameter.this[0].name, aws_ssm_parameter.ignore_value[0].name, null)
}

output "ssm_parameter_type" {
  description = "Type of the parameter"
  value       = try(aws_ssm_parameter.this[0].type, aws_ssm_parameter.ignore_value[0].type, null)
}

output "ssm_parameter_version" {
  description = "Version of the parameter"
  value       = try(aws_ssm_parameter.this[0].version, aws_ssm_parameter.ignore_value[0].version, null)
}

output "value" {
  description = "Value of a `String`/`StringList` parameter after jsondecode() where possible. Always null for `SecureString`."
  value       = try(jsondecode(local.insecure_value), local.insecure_value)
}
