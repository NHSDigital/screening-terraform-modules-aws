data "aws_lambda_function" "lambda_function" {
  function_name = "${var.name_prefix}-${var.function_name}"
}

# ---- Allow EventBridge to invoke Lambda ----
resource "aws_iam_role" "scheduler_invoke" {
  name = "${var.name_prefix}-scheduler-invoke-${var.resource_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "scheduler_lambda_policy" {
  role = aws_iam_role.scheduler_invoke.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "lambda:InvokeFunction",
        Resource = data.aws_lambda_function.lambda_function.arn
      }
    ]
  })
}

# ---- EventBridge one-time schedule ----
resource "aws_scheduler_schedule" "env_expiry" {
  name = "${var.name_prefix}-expire-${var.resource_suffix}"


  # Note schedulers often fire an initial event upon creation, setting the "start_date" prevents this
  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = "Europe/London"
  start_date                   = var.start_time

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = data.aws_lambda_function.lambda_function.arn
    role_arn = aws_iam_role.scheduler_invoke.arn
    input    = jsonencode(var.lambda_inputs)
  }
}
