# Lambda function to validate restored RDS instances during backup restore testing
# This Lambda is triggered by EventBridge when a restore testing job completes

data "archive_file" "lambda_restore_validation_zip" {
  count       = var.backup_plan_config_rds.enable && var.restore_validation_enable ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/../../lambdas/restore_validation/resources"
  output_path = "${path.module}/.terraform/archive_files/lambda_restore_validation.zip"
}

resource "aws_iam_role" "restore_validation_lambda" {
  count = var.backup_plan_config_rds.enable && var.restore_validation_enable ? 1 : 0
  name  = "${local.resource_name_prefix}-backup-restore-validation-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  permissions_boundary = length(var.iam_role_permissions_boundary) > 0 ? var.iam_role_permissions_boundary : null
}

resource "aws_iam_policy" "restore_validation_lambda" {
  count = var.backup_plan_config_rds.enable && var.restore_validation_enable ? 1 : 0
  name  = "${local.resource_name_prefix}-backup-restore-validation-lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "CloudWatchLogs"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
        Effect   = "Allow"
      },
      {
        Sid = "BackupDescribe"
        Action = [
          "backup:DescribeRestoreJob",
          "backup:PutRestoreValidationResult"
        ]
        Resource = "*"
        Effect   = "Allow"
      },
      {
        Sid = "RDSDescribe"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:ListTagsForResource"
        ]
        Resource = "*"
        Effect   = "Allow"
      },
      {
        Sid    = "SecretsManagerRead"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [
          "arn:aws:secretsmanager:${data.aws_region.current.region}:${local.local_account_id}:secret:bss-${var.environment_name}-${var.nation}-bss_user-*"
        ]
        Effect = "Allow"
      },
      {
        Sid = "EC2NetworkInfo"
        Action = [
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "restore_validation_lambda_policy" {
  count      = var.backup_plan_config_rds.enable && var.restore_validation_enable ? 1 : 0
  role       = aws_iam_role.restore_validation_lambda[0].name
  policy_arn = aws_iam_policy.restore_validation_lambda[0].arn
}

# VPC configuration for Lambda to access RDS in private subnets
resource "aws_iam_role_policy_attachment" "restore_validation_lambda_vpc" {
  count      = var.backup_plan_config_rds.enable && var.restore_validation_enable ? 1 : 0
  role       = aws_iam_role.restore_validation_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}


module "lambda_layer" {
  source              = "../../modules/lambda-layer"
  name_prefix         = var.name_prefix
  layer_name          = "psycopg"
  compatible_runtimes = [var.python_version]
  description         = "Lambda layer for calling postgres"
}

resource "aws_lambda_function" "restore_validation" {
  count            = var.backup_plan_config_rds.enable && var.restore_validation_enable ? 1 : 0
  function_name    = "${local.resource_name_prefix}-backup-restore-validation"
  role             = aws_iam_role.restore_validation_lambda[0].arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda_restore_validation_zip[0].output_path
  source_code_hash = data.archive_file.lambda_restore_validation_zip[0].output_base64sha256
  timeout          = var.restore_validation_timeout_seconds
  layers           = [module.lambda_layer.layer_arn]
  environment {
    variables = {
      DB_CREDENTIALS_SECRET   = var.restore_validation_db_credentials_secret_name
      EXPECTED_SUBNET_PATTERN = var.restore_validation_expected_subnet_pattern
      RESTORE_DB_NAME         = var.restore_testing_db_name
    }
  }

  vpc_config {
    subnet_ids         = data.terraform_remote_state.vpc.outputs.vpc_private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.restore_validation_lambda_policy
  ]
}

######################
# Security Group
######################

resource "aws_security_group" "lambda" {
  name        = "${var.name_prefix}-dbbackup-restore-test-lambda"
  description = "Security group for dbbackup-restore-test Lambda"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "lambda_egress_https" {
  security_group_id = aws_security_group.lambda.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
  description       = "Allow outbound HTTPS traffic for AWS service calls"

  tags = {
    Name = "Allow Outbound 443"
  }
}

resource "aws_vpc_security_group_egress_rule" "lambda_egress_for_rds" {
  security_group_id            = aws_security_group.lambda.id
  referenced_security_group_id = data.terraform_remote_state.rds_instance.outputs.rds_sg_id
  from_port                    = 5432
  ip_protocol                  = "tcp"
  to_port                      = 5432
  description                  = "A rule to allow outbound connections from the lambda Restore Validation SG to the RDS"
}

resource "aws_vpc_security_group_ingress_rule" "lambda_ingress_for_rds" {
  security_group_id            = data.terraform_remote_state.rds_instance.outputs.rds_sg_id
  referenced_security_group_id = aws_security_group.lambda.id

  from_port   = 5432
  ip_protocol = "tcp"
  to_port     = 5432
  description = "A rule to allow inbound connections to RDS from the lambda Restore Validation SG"

}

# EventBridge rule to trigger validation when restore testing completes
resource "aws_cloudwatch_event_rule" "restore_testing_complete" {
  count       = var.backup_plan_config_rds.enable && var.restore_validation_enable ? 1 : 0
  name        = "${local.resource_name_prefix}-backup-restore-testing-complete"
  description = "Trigger validation when AWS Backup restore testing completes"

  event_pattern = jsonencode({
    source      = ["aws.backup"]
    detail-type = ["Restore Job State Change"]
    detail = {
      status = ["COMPLETED"]
    }
  })
}

resource "aws_cloudwatch_event_target" "restore_validation" {
  count     = var.backup_plan_config_rds.enable && var.restore_validation_enable ? 1 : 0
  rule      = aws_cloudwatch_event_rule.restore_testing_complete[0].name
  target_id = "RestoreValidationLambda"
  arn       = aws_lambda_function.restore_validation[0].arn
}

resource "aws_lambda_permission" "eventbridge_invoke_validation" {
  count         = var.backup_plan_config_rds.enable && var.restore_validation_enable ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.restore_validation[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.restore_testing_complete[0].arn
}

# CloudWatch Log Group for Lambda logs
resource "aws_cloudwatch_log_group" "restore_validation" {
  count             = var.backup_plan_config_rds.enable && var.restore_validation_enable ? 1 : 0
  name              = "/aws/lambda/${local.resource_name_prefix}-backup-restore-validation"
  retention_in_days = var.restore_validation_log_retention_days

  tags = {
    Name        = "${local.resource_name_prefix}-backup-restore-validation-logs"
    Environment = var.environment_name
  }
}
