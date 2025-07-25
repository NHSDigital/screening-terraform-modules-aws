resource "aws_iam_policy" "cw_lambda_iam_policy" {
  name   = "${var.name_prefix}_cw_lambda"
  policy = data.aws_iam_policy_document.cw_lambda_doc_policy.json
}

data "aws_iam_policy_document" "cw_lambda_doc_policy" {
  statement {
    actions = [
      "logs:*"
    ]
    resources = [
      "arn:aws:logs:eu-west-2:${var.aws_account_id}:log-group:*"
    ]
  }
  statement {
    actions = [
      "firehose:Put*"
    ]
    resources = [
      "arn:aws:firehose:eu-west-2:${var.aws_account_id}:deliverystream/${var.name_prefix}-cw-logs-firehose"
    ]
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "lambdaAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cw_lambda_iam_role" {
  name               = "${var.name_prefix}_cw_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "cw_lambda_att" {
  policy_arn = aws_iam_policy.cw_lambda_iam_policy.arn
  role       = aws_iam_role.cw_lambda_iam_role.id
}
