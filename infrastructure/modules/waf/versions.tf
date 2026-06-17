terraform {
  required_version = ">= 1.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.42"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.14"
    }
  }
}
