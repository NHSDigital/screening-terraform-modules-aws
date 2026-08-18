output "api_id" {
  description = "The ID of the HTTP API."
  value       = try(aws_apigatewayv2_api.this[0].id, null)
}

output "api_endpoint" {
  description = "The base invoke URL of the HTTP API."
  value       = try(aws_apigatewayv2_api.this[0].api_endpoint, null)
}

output "execution_arn" {
  description = "The execution ARN of the HTTP API, suitable for IAM policies or permissions."
  value       = try(aws_apigatewayv2_api.this[0].execution_arn, null)
}

output "stage_name" {
  description = "The deployed stage name."
  value       = try(aws_apigatewayv2_stage.this[0].name, null)
}

output "route_id" {
  description = "The ID of the webhook route."
  value       = try(aws_apigatewayv2_route.this[0].id, null)
}

output "integration_id" {
  description = "The ID of the Lambda proxy integration."
  value       = try(aws_apigatewayv2_integration.this[0].id, null)
}
