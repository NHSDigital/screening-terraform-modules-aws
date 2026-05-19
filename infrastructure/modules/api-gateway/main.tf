###########
# Secrets #
###########
resource "random_password" "api_auth_token" {
  length  = 20
  special = false
}

resource "aws_secretsmanager_secret" "api_token" {
  name        = "${var.name_prefix}-${var.api_gateway_name}-api"
  description = "Auth token for api gateway"

  dynamic "replica" {
    for_each = var.secret_replication_regions
    content {
      region = replica.value
    }
  }
}

resource "aws_secretsmanager_secret_version" "api_token" {
  secret_id     = aws_secretsmanager_secret.api_token.id
  secret_string = random_password.api_auth_token.result
}



################
# API Gateway  #
################

# API Gateway REST API
resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.name_prefix}-${var.api_gateway_name}"
  description = var.api_gateway_description

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  lifecycle {
    create_before_destroy = true
  }
}



# API Resource
resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = var.api_path_part
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id      = aws_api_gateway_rest_api.api.id
  resource_id      = aws_api_gateway_resource.api_resource.id
  http_method      = var.http_method
  authorization    = "NONE"
  api_key_required = true
}

# Integration with Lambda
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.api_resource.id
  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.aws_lambda_arn
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.aws_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# Deploy API Gateway
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration]

  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment_trigger = sha1(jsonencode(aws_api_gateway_integration.lambda_integration))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id        = aws_api_gateway_deployment.deployment.id
  rest_api_id          = aws_api_gateway_rest_api.api.id
  stage_name           = var.stage_name
  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.log_group.arn
    format          = "{\"requestId\":\"$context.requestId\",\"ip\":\"$context.identity.sourceIp\",\"user\":\"$context.identity.user\",\"requestTime\":\"$context.requestTime\",\"httpMethod\":\"$context.httpMethod\",\"resourcePath\":\"$context.resourcePath\",\"status\":\"$context.status\",\"protocol\":\"$context.protocol\",\"responseLength\":\"$context.responseLength\"}"
  }
}

##########################
# API Key and Usage Plan #
##########################
resource "aws_api_gateway_api_key" "my_api_key" {
  name    = "${var.name_prefix}-${var.api_gateway_name}-api-key-${var.api_gateway_name}"
  enabled = true
  value   = aws_secretsmanager_secret_version.api_token.secret_string
}

resource "aws_api_gateway_usage_plan" "usage_plan" {
  depends_on  = [aws_api_gateway_stage.stage]
  name        = "${var.name_prefix}-${var.api_gateway_name}-usage-plan"
  description = "The usage plan used for the ${var.name_prefix}-${var.api_gateway_name} endpoint"

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.stage.stage_name
  }

  quota_settings {
    limit  = 1000
    period = "WEEK"
  }

  throttle_settings {
    burst_limit = 25
    rate_limit  = 50
  }
}

resource "aws_api_gateway_usage_plan_key" "usage_plan_key" {
  key_id        = aws_api_gateway_api_key.my_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan.id
}


####################
# cloudwatch       #
####################

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "${var.name_prefix}-api-gateway-Execution-Logs_${aws_api_gateway_rest_api.api.id}/${var.name_prefix}-${var.api_gateway_name}"
  retention_in_days = 365
}


###############################################
# IAM roles API Gateway logs account settings #
###############################################
resource "aws_iam_role" "apigateway_cloudwatch" {
  name = "${var.name_prefix}-apigateway-cloudwatch-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "apigateway.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "apigateway_logs" {
  role       = aws_iam_role.apigateway_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "account" {
  cloudwatch_role_arn = aws_iam_role.apigateway_cloudwatch.arn
}

######################
# route 53  and Cert #
######################

resource "aws_acm_certificate" "cert" {
  count                     = var.certificate_arn == null ? 1 : 0
  domain_name               = var.hosted_zone_name
  subject_alternative_names = ["${var.domain_name_prefix}.${var.hosted_zone_name}"]
  validation_method         = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  for_each = var.certificate_arn == null ? {
    for dvo in aws_acm_certificate.cert[0].domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  zone_id = var.route53_hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "cert_validation" {
  count           = var.certificate_arn == null ? 1 : 0
  certificate_arn = aws_acm_certificate.cert[0].arn

  validation_record_fqdns = [
    for record in aws_route53_record.cert_validation : record.fqdn
  ]
}

# Use existing wildcard certificate from DNS stack or newly created certificate
resource "aws_api_gateway_domain_name" "gateway_domain_name" {
  domain_name              = "${var.domain_name_prefix}.${var.hosted_zone_name}"
  regional_certificate_arn = var.certificate_arn != null ? var.certificate_arn : aws_acm_certificate_validation.cert_validation[0].certificate_arn
  security_policy          = "TLS_1_2"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}


resource "aws_route53_record" "route53_record" {
  name    = "${var.domain_name_prefix}.${var.hosted_zone_name}"
  type    = "A"
  zone_id = var.route53_hosted_zone_id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.gateway_domain_name.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.gateway_domain_name.regional_zone_id
  }
}

#map to custom domain dont hit default API Gateway domain
resource "aws_api_gateway_base_path_mapping" "custom_domain_mapping" {
  api_id      = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  domain_name = aws_api_gateway_domain_name.gateway_domain_name.domain_name
  base_path   = var.stage_name

  depends_on = [aws_api_gateway_stage.stage]
}
