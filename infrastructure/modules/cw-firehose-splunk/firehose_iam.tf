resource "aws_iam_policy" "cw_firehose_iam_policy" {
  name   = "${var.name_prefix}_cw_firehose"
  policy = data.aws_iam_policy_document.cw_firehose_doc_policy.json
}

data "aws_iam_policy_document" "cw_firehose_doc_policy" {
  statement {
    actions = ["logs:*"]
    resources = [
      "arn:aws:logs:eu-west-2:${var.aws_account_id}:*",
      "arn:aws:logs:eu-west-2:${var.aws_account_id}:log-group:*:*"
    ]
  }
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:eu-west-2:${var.aws_account_id}:log-group:*"]
  }
  statement {
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${var.name_prefix}-cw-fh-dead-letter*",
      "arn:aws:s3:::${var.name_prefix}-cw-fh-dead-letter/*"
    ]
  }
  statement {
    actions = ["firehose:*"]
    resources = [
      "arn:aws:firehose:eu-west-2:${var.aws_account_id}:deliverystream/${var.name_prefix}*"
    ]
  }
  statement {
    actions = ["firehose:ListDeliveryStreams"]
    resources = [
      "*"
    ]
  }
  statement {
    actions = [
      "lambda:*"
    ]
    resources = [
      "arn:aws:lambda:eu-west-2:${var.aws_account_id}:function:${var.name_prefix}*:*",
      "arn:aws:lambda:eu-west-2:${var.aws_account_id}:function:${var.name_prefix}*"
    ]
  }
}

data "aws_iam_policy_document" "cw_firehose_assume_role" {
  statement {
    sid     = "firehoseAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com", "logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cw_firehose_iam_role" {
  name               = "${var.name_prefix}_cw_firehose_access_role"
  assume_role_policy = data.aws_iam_policy_document.cw_firehose_assume_role.json
}

resource "aws_iam_role_policy_attachment" "cw_firehose_att" {
  policy_arn = aws_iam_policy.cw_firehose_iam_policy.arn
  role       = aws_iam_role.cw_firehose_iam_role.id
}
