
output "function_name" {
  value = module.lambda_function.lambda_function_name
}

output "arn" {
  value = module.lambda_function.lambda_function_invoke_arn
}

output "role_name" {
  value = module.lambda_function.lambda_role_name
}

output "lambda_arn" {
  value = module.lambda_function.lambda_function_arn
}

output "lambda_log_group_name" {
  value = "/aws/lambda/${module.lambda_function.lambda_function_name}"
}
