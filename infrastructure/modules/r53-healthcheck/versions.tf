terraform {
  required_version = ">= 1.13"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.42"
      configuration_aliases = [aws.us_east_1]
    }
  }
}
