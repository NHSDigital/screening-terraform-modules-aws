data "aws_iam_policy_document" "queue" {
  count = module.this.enabled ? 1 : 0

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:*"]
    resources = [aws_sqs_queue.this[0].arn]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  dynamic "statement" {
    for_each = var.publisher_statements

    content {
      sid    = substr(regexreplace(statement.key, "[^A-Za-z0-9]", ""), 0, 80)
      effect = "Allow"

      actions   = ["sqs:SendMessage"]
      resources = [aws_sqs_queue.this[0].arn]

      principals {
        type        = statement.value.principals.type
        identifiers = statement.value.principals.identifiers
      }

      dynamic "condition" {
        for_each = length(statement.value.source_arns) > 0 ? [statement.value.source_arns] : []

        content {
          test     = "ArnEquals"
          variable = "aws:SourceArn"
          values   = condition.value
        }
      }

      dynamic "condition" {
        for_each = length(statement.value.source_accounts) > 0 ? [statement.value.source_accounts] : []

        content {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = condition.value
        }
      }
    }
  }
}
