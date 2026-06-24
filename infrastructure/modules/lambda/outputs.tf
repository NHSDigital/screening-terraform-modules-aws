
output "function_name" {
  description = "Name of the Lambda function."
  value       = module.lambda_function.lambda_function_name
}

output "arn" {
  description = "Invoke ARN of the Lambda function."
  value       = module.lambda_function.lambda_function_invoke_arn
}

output "role_name" {
  description = "IAM role name used by the Lambda function."
  value       = module.lambda_function.lambda_role_name
}

output "lambda_arn" {
  description = "ARN of the Lambda function."
  value       = module.lambda_function.lambda_function_arn
}

output "lambda_log_group_name" {
  description = "CloudWatch Logs log group name for the Lambda function."
  value       = "/aws/lambda/${module.lambda_function.lambda_function_name}"
}
