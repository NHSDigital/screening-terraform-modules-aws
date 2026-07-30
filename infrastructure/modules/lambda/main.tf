###############
# lambda      #
###############

module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"
  # downgrade version as workaround for bug https://github.com/terraform-aws-modules/terraform-aws-lambda/issues/733
  version = "8.8.0"

  function_name          = local.function_name
  description            = var.function_description
  handler                = "${var.handler_prefix}.lambda_handler"
  runtime                = var.python_version
  source_path            = var.source_path != null ? var.source_path : "../../lambdas/${var.handler_prefix}/"
  timeout                = var.timeout
  layers                 = var.layers
  environment_variables  = var.environment_variables
  vpc_subnet_ids         = var.vpc_subnet_ids
  vpc_security_group_ids = var.vpc_security_group_ids

  # Tags — automatically populated from context
  tags = module.this.tags
}

###############
# IAM Policy  #
###############

resource "aws_iam_role_policy_attachment" "vpc_access_execution" {
  role       = module.lambda_function.lambda_role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_to_cw_policy" {
  role       = module.lambda_function.lambda_role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "push_to_cloudwatch" {
  role       = module.lambda_function.lambda_role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_iam_role_policy_attachment" "sqs" {
  role       = module.lambda_function.lambda_role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}
