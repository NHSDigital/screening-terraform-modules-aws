output "api_gateway_id" {
  description = "The ID of the API Gateway"
  value       = aws_api_gateway_rest_api.api.id
}

output "api_gateway_url" {
  description = "The URL of the API Gateway custom domain"
  value       = "https://${aws_api_gateway_domain_name.gateway_domain_name.domain_name}/${var.api_path_part}"
}

output "api_gateway_invoke_url" {
  description = "The invoke URL of the API Gateway stage"
  value       = aws_api_gateway_stage.stage.invoke_url
}

output "api_key_id" {
  description = "The ID of the API key"
  value       = aws_api_gateway_api_key.my_api_key.id
}

output "api_key_secret_arn" {
  description = "The ARN of the API key secret in Secrets Manager"
  value       = aws_secretsmanager_secret.api_token.arn
}
