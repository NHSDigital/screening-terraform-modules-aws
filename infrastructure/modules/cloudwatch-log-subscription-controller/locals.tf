locals {
  eventbridge_rule_key = "${substr(module.this.id, 0, 43)}-${substr(sha1(module.this.id), 0, 8)}"
  lambda_function_name = "${substr(module.this.id, 0, 50)}-controller"

  log_group_resource_arns = [
    for prefix in var.log_group_prefixes : "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:${prefix}*:*"
  ]

  lambda_log_group_name = "/aws/lambda/${local.lambda_function_name}"

  execution_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:DescribeSubscriptionFilters", "logs:PutSubscriptionFilter"]
        Resource = local.log_group_resource_arns
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = [var.subscription_role_arn]
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "logs.${data.aws_region.current.region}.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = [
          "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:${local.lambda_log_group_name}:*"
        ]
      }
    ]
  })
}
