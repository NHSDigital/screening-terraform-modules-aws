terraform {
  required_version = ">= 1.5.7"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.8.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.47.0"
    }

    local = {
      source  = "hashicorp/local"
      version = ">= 2.9.0"
    }
  }
}
