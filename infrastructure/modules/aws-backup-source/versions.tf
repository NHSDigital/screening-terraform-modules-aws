terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "> 6"
    }
  }

  required_version = ">= 1.9.5"
}
