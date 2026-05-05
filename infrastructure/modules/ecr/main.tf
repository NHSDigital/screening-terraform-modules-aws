resource "aws_ecr_repository" "image_repository" {
  name = "${var.name_prefix}-${var.repo_name}"
}

resource "aws_ecr_repository_policy" "ecr_repo_policy" {
  repository = aws_ecr_repository.image_repository.name
  policy     = data.aws_iam_policy_document.ecr_repo_policy_document.json
}

data "aws_iam_policy_document" "ecr_repo_policy_document" {
  # Pushing images restricted to GitHub actions and developer roles only
  statement {
    sid    = "AllowGitHubBuildAndPush"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.aws_account_id}:root"
      ]
    }
    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values = [
        "arn:aws:iam::${local.aws_account_id}:role/${var.name_prefix}-github-actions-role",
        "arn:aws:iam::${local.aws_account_id}:role/aws-reserved/sso.amazonaws.com/eu-west-2/${var.developer_sso_role}"
      ]
    }
  }
  # Allow pulling of images from other BSS native accounts (e.g. read-only access by ECS)
  statement {
    sid    = "AllowAllPullImage"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    principals {
      type = "AWS"
      identifiers = [
        for id in local.aws_account_ids : "arn:aws:iam::${id}:root"
      ]
    }
  }
}

# Dynamic lifecycle policy rules
data "aws_ecr_lifecycle_policy_document" "ecr" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0
  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      priority    = rule.value.priority
      description = rule.value.description

      selection {
        tag_status       = rule.value.selection.tag_status
        tag_prefix_list  = lookup(rule.value.selection, "tag_prefix_list", null)
        tag_pattern_list = lookup(rule.value.selection, "tag_pattern_list", null)
        count_type       = rule.value.selection.count_type
        count_number     = rule.value.selection.count_number
        count_unit       = lookup(rule.value.selection, "count_unit", null)
      }
    }
  }
}

resource "aws_ecr_lifecycle_policy" "ecr" {
  count      = length(var.lifecycle_rules) > 0 ? 1 : 0
  repository = aws_ecr_repository.image_repository.name
  policy     = data.aws_ecr_lifecycle_policy_document.ecr[0].json
}
