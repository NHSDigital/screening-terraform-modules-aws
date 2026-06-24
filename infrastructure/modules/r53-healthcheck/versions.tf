terraform {
  required_version = ">= 1.13"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.7.0"
    }

    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.42"
      configuration_aliases = [aws.us_east_1]
    }
  }
}
