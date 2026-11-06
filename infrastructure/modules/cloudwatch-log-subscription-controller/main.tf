################################################################
# Continuous CloudWatch Logs subscription enrolment
#
# Subscribes log groups created after deployment when their names
# match configured prefixes. Existing groups are managed by the
# cloudwatch-log-subscription-filter module.
################################################################

module "controller_logs" {
  source = "../cloudwatch-logs"

  context           = module.this.context
  name              = "${module.this.name}-controller-logs"
  log_group_name    = local.lambda_log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id
}

module "controller" {
  source = "../lambda"

  context                       = module.this.context
  name                          = "${module.this.name}-subscription-controller"
  function_name                 = local.lambda_function_name
  handler_prefix                = "function"
  handler                       = "function.handler"
  function_description          = "Subscribe newly created matching CloudWatch log groups to the OTLP Firehose stream"
  python_version                = var.python_version
  source_path                   = "${path.module}/../../lambdas/cloudwatch_log_subscription_controller"
  timeout                       = 30
  attach_default_policies       = false
  attach_cloudwatch_logs_policy = false
  execution_policy_json         = local.execution_policy_json
  environment_variables = {
    LOG_GROUP_PREFIXES     = jsonencode(var.log_group_prefixes)
    PREFIX_FILTER_PATTERNS = jsonencode(var.prefix_filter_patterns)
    PREFIX_EXCLUDE_REGEXES = jsonencode(var.prefix_exclude_regexes)
    DESTINATION_ARN        = var.destination_arn
    SUBSCRIPTION_ROLE_ARN  = var.subscription_role_arn
    FILTER_NAME            = module.this.id
    FILTER_PATTERN         = var.filter_pattern
  }
}

module "eventbridge" {
  source = "../eventbridge"

  context = module.this.context
  name    = "${module.this.name}-eventbridge"

  aws_region                 = data.aws_region.current.region
  bus_name                   = "default"
  kms_key_identifier         = "alias/aws/events"
  create_role                = false
  create_bus                 = false
  create_rules               = true
  create_targets             = true
  create_permissions         = false
  create_archives            = false
  create_schedule_groups     = false
  create_schedules           = false
  create_pipes               = false
  create_log_delivery_source = false
  create_log_delivery        = false

  rules = {
    (local.eventbridge_rule_key) = {
      description = "Enrol newly created matching log groups in the OTLP subscription"
      event_pattern = jsonencode({
        source        = ["aws.logs"]
        "detail-type" = ["AWS API Call via CloudTrail"]
        detail = {
          eventSource = ["logs.amazonaws.com"]
          eventName   = ["CreateLogGroup"]
        }
      })
    }
  }

  targets = {
    (local.eventbridge_rule_key) = [{
      name            = "subscription-controller"
      target_id       = "${module.this.id}-controller"
      arn             = module.controller.lambda_arn
      dead_letter_arn = var.dead_letter_queue_arn
      retry_policy = {
        maximum_event_age_in_seconds = 86400
        maximum_retry_attempts       = 185
      }
    }]
  }
}

resource "aws_lambda_permission" "eventbridge" {
  count = module.this.enabled ? 1 : 0

  statement_id  = "AllowEventBridgeCreateLogGroupEvents"
  action        = "lambda:InvokeFunction"
  function_name = module.controller.function_name
  principal     = "events.amazonaws.com"
  source_arn    = try(module.eventbridge.eventbridge_rule_arns[local.eventbridge_rule_key], null)
}
