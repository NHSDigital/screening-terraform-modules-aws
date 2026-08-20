################################################################
# API Gateway HTTP API
#
# Minimal NHS wrapper for the GitHub ARC webhook publisher use case.
# Creates a single API Gateway v2 HTTP API with:
#
#   * Lambda proxy integration for a webhook endpoint
#   * Single route definition
#   * Default stage with auto deploy enabled
#   * Access logging to CloudWatch Logs
#   * Lambda invoke permission scoped to this API
#
# Naming and tagging are derived from context.tf via module.this.
################################################################

resource "aws_cloudwatch_log_group" "this" {
  count = module.this.enabled ? 1 : 0

  name              = "/aws/apigateway/${local.api_name}"
  retention_in_days = var.access_log_retention_in_days

  tags = module.this.tags
}

resource "aws_apigatewayv2_api" "this" {
  count = module.this.enabled ? 1 : 0

  name          = local.api_name
  protocol_type = "HTTP"
  description   = var.description

  tags = module.this.tags
}

resource "aws_apigatewayv2_integration" "this" {
  count = module.this.enabled ? 1 : 0

  api_id                 = aws_apigatewayv2_api.this[0].id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = var.lambda_invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = var.integration_timeout_milliseconds
}

resource "aws_apigatewayv2_route" "this" {
  count = module.this.enabled ? 1 : 0

  api_id    = aws_apigatewayv2_api.this[0].id
  route_key = var.route_key
  target    = "integrations/${aws_apigatewayv2_integration.this[0].id}"
}

resource "aws_apigatewayv2_stage" "this" {
  count = module.this.enabled ? 1 : 0

  api_id      = aws_apigatewayv2_api.this[0].id
  name        = var.stage_name
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.this[0].arn
    format          = local.access_log_format
  }

  default_route_settings {
    detailed_metrics_enabled = var.enable_detailed_metrics
    throttling_burst_limit   = var.default_route_throttling_burst_limit
    throttling_rate_limit    = var.default_route_throttling_rate_limit
  }

  tags = module.this.tags
}

resource "aws_lambda_permission" "this" {
  count = module.this.enabled ? 1 : 0

  statement_id  = "AllowExecutionFromApiGateway-${replace(local.api_name, "[^a-zA-Z0-9]", "")}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name_or_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this[0].execution_arn}/*"
}
