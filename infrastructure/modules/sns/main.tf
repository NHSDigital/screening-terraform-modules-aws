#################
#  SNS          #
#################

resource "aws_sns_topic" "sns_topic" {
  name                        = var.name_prefix
  fifo_topic                  = false
  content_based_deduplication = false
}

resource "aws_sns_topic_policy" "sns_topic_policy" {
  arn    = aws_sns_topic.sns_topic.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__default_policy_ID"
  statement {
    sid = "default_statement_actions"
    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish"
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [var.aws_account_id]
    }
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect = "Allow"

    resources = ["arn:aws:sns:eu-west-2:${var.aws_account_id}:${aws_sns_topic.sns_topic.name}"]
  }


  # Allows our eventbridge rules to publish to our topic
  statement {
    sid = "allow event bridge actions"
    actions = [
      "sns:Publish",
    ]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    effect = "Allow"

    resources = ["arn:aws:sns:eu-west-2:${var.aws_account_id}:${aws_sns_topic.sns_topic.name}"]
  }

  # Allows our Elasticache to publish to our topic
  statement {
    sid = "allow event from elasticache"
    actions = [
      "sns:Publish",
    ]
    principals {
      type        = "Service"
      identifiers = ["elasticache.amazonaws.com"]
    }
    effect = "Allow"

    resources = ["arn:aws:sns:eu-west-2:${var.aws_account_id}:${aws_sns_topic.sns_topic.name}"]
  }

  # Allows our S3 to publish to our topic
  # statement {
  #     sid = "allow event from alb-logs s3 bucket"
  #     actions = [
  #       "sns:Publish",
  #     ]
  #     principals {
  #       type        = "Service"
  #       identifiers = ["s3.amazonaws.com"]
  #     }
  #     effect = "Allow"

  #     resources = ["arn:aws:sns:eu-west-2:${var.aws_account_id}:${var.sns_topic}"]
  #     condition {
  #      test     = "ArnEquals"
  #      values   = ["arn:aws:s3:::${var.alb_log_bucket_name}"]
  #      variable = "aws:SourceArn"
  #    }
  # }

  # Allows our ECS to publish to our topic
  statement {
    sid    = "AllowAllECSTasksToPublish"
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      "arn:aws:sns:eu-west-2:${var.aws_account_id}:${aws_sns_topic.sns_topic.name}"
    ]

    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values = [
        "arn:aws:iam::${var.aws_account_id}:role/${var.name_prefix}-ecs*"
      ]
    }
  }
}
