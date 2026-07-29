terraform {
  required_version = ">= 1.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.42" # Platform baseline; terraform-aws-modules/vpc 6.6.1 supports this
    }
  }
}
