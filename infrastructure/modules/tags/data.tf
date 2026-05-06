data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_session_context" "current" {
  # This data source provides information on the source
  # IAM role when an assumed role is utilized
  arn = data.aws_caller_identity.current.arn
}
