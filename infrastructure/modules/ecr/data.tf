data "aws_caller_identity" "current" {}

locals {
  aws_account_id  = data.aws_caller_identity.current.account_id
  aws_account_ids = jsondecode(data.aws_secretsmanager_secret_version.aws_account_ids.secret_string)
}

data "aws_secretsmanager_secret" "aws_account_ids" {
  name = "${var.name_prefix}-aws-account-ids"
}

data "aws_secretsmanager_secret_version" "aws_account_ids" {
  secret_id = data.aws_secretsmanager_secret.aws_account_ids.id
}
