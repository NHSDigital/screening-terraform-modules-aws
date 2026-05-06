# ################################################################
# # R53 Health Check
# ################################################################

resource "aws_route53_health_check" "bs_select_health_check_web_app" {

  fqdn              = local.fqdn #Change to local.fqdn
  port              = 443
  type              = "HTTPS"
  resource_path     = "/bss/health"
  failure_threshold = "3"
  request_interval  = "30"
  regions           = ["eu-west-1", "us-east-1", "us-west-1"]

  tags = {
    Name = "${var.name_prefix}-${local.env}-web-app"
  }
}

# ##############################################################
# # Forwarder SNS (us-east-1)
# ##############################################################
resource "aws_sns_topic" "forwarder_topic" {
  provider = aws.us_east_1
  name     = "${var.name_prefix}-${local.env}-r53-forwarder"
}

# ##############################################################
# # Lambda Role
# ##############################################################
resource "aws_iam_role" "lambda_role" {
  provider = aws.us_east_1
  name     = "${var.name_prefix}-${local.env}-sns-forwarder-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "basic_lambda" {
  provider   = aws.us_east_1
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "sns_publish_policy" {
  provider = aws.us_east_1
  role     = aws_iam_role.lambda_role.id
  name     = "${var.name_prefix}-${local.env}-sns-forwarder-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["sns:Publish"],
      Resource = var.sns_topic
    }]
  })
}

# ##############################################################
# # Lambda function
# ##############################################################
data "archive_file" "sns_forwarder_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_function/"
  output_path = "${path.module}/.terraform/archive_files/bs-select-sns-forwarder.zip"
}

resource "aws_lambda_function" "sns_forwarder" {
  provider      = aws.us_east_1
  filename      = data.archive_file.sns_forwarder_zip.output_path
  function_name = "${var.name_prefix}-${local.env}-sns-forwarder"
  handler       = "bs-select-sns-forwarder.lambda_handler"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.12"
  timeout       = 120

  environment {
    variables = {
      EU_WEST_2_SNS = var.sns_topic
    }
  }
}

# ##############################################################
# # SNS subscription to Lambda
# ##############################################################
resource "aws_sns_topic_subscription" "forwarder_sub" {
  provider  = aws.us_east_1
  topic_arn = aws_sns_topic.forwarder_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.sns_forwarder.arn
}

resource "aws_lambda_permission" "allow_sns" {
  provider      = aws.us_east_1
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sns_forwarder.arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.forwarder_topic.arn
}


# ##############################################################
# # Route53 Health Checks Cloud Watch Alarm
# ##############################################################

resource "aws_cloudwatch_metric_alarm" "bs_select_health_check_web_app_healthy" {
  provider            = aws.us_east_1
  alarm_name          = "${var.name_prefix}-${local.env}-web-app-healthy"
  namespace           = "AWS/Route53"
  metric_name         = "HealthCheckStatus"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  unit                = "None"
  dimensions = {
    HealthCheckId = aws_route53_health_check.bs_select_health_check_web_app.id
  }
  alarm_description         = "When in alarm, send message to topic ${aws_sns_topic.forwarder_topic.arn}"
  alarm_actions             = [aws_sns_topic.forwarder_topic.arn]
  ok_actions                = [aws_sns_topic.forwarder_topic.arn]
  insufficient_data_actions = []
  treat_missing_data        = "notBreaching"
}
