terraform {
  required_version = ">= 1.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.42"
    }

    awscc = {
      source = "hashicorp/awscc"
    }
  }
}
