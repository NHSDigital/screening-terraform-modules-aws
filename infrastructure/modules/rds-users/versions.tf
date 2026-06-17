terraform {
  required_version = ">= 1.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.42"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.9"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = ">= 1.25.0"
    }
  }
}
