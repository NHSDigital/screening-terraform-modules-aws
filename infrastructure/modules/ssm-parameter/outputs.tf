output "insecure_value" {
  description = "Insecure value of the parameter"
  value       = module.ssm_parameter.insecure_value
}

output "raw_value" {
  description = "Raw value of the parameter (as it is stored in SSM). Use 'value' output to get jsondecode'd value"
  value       = module.ssm_parameter.raw_value
  sensitive   = true
}

output "secure_type" {
  description = "Whether SSM parameter is a SecureString or not?"
  value       = module.ssm_parameter.secure_type
}

output "secure_value" {
  description = "Secure value of the parameter"
  value       = module.ssm_parameter.secure_value
  sensitive   = true
}

output "ssm_parameter_arn" {
  description = "The ARN of the parameter"
  value       = module.ssm_parameter.ssm_parameter_arn
}

output "ssm_parameter_name" {
  description = "Name of the parameter"
  value       = module.ssm_parameter.ssm_parameter_name
}

output "ssm_parameter_type" {
  description = "Type of the parameter"
  value       = module.ssm_parameter.ssm_parameter_type
}

output "ssm_parameter_version" {
  description = "Version of the parameter"
  value       = module.ssm_parameter.ssm_parameter_version
}

output "value" {
  description = "Parameter value after jsondecode(). Probably this is what you are looking for"
  value       = module.ssm_parameter.value
}
