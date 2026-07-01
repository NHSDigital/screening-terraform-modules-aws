terraform {
  required_version = ">= 1.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.42"
    }

    awscc = {
      # Not used directly in this module
      # Used by `lgallard/cognito-user-pool/aws` for managed login branding
      # Not clear what the minimum version should be
      source  = "hashicorp/awscc"
      version = ">= 1.89"
    }
  }
}
