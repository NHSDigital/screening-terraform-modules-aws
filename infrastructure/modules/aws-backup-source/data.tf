data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# tflint-ignore: terraform_unused_declarations
data "aws_iam_roles" "roles" {
  name_regex  = "AWSReservedSSO_Admin_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

locals {
  local_account_id = data.aws_caller_identity.current.account_id
}

######################
# Terraform Remote State
######################

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "bss-${var.environment_name}-${var.nation}-terraform-state"
    key    = "terraform-state/vpc.tfstate"
    region = "eu-west-2"
  }
}

data "terraform_remote_state" "rds_instance" {
  backend = "s3"

  config = {
    bucket = "bss-${var.environment_name}-${var.nation}-terraform-state"
    key    = "terraform-state/rds-instance.tfstate"
    region = "eu-west-2"
  }
}
