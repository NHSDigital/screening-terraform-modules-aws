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
      # Pinned to the NHS platform provider baseline that supports this usage
      source  = "hashicorp/awscc"
      version = ">= 1.89"
    }
  }
}
