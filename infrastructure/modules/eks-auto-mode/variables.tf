variable "environment" {
  description = "The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD"
  type        = string
}

variable "name" {
  description = "The name of the resource"
  type        = string
  default     = "-eks"
}

variable "cluster_version" {
  description = "The version of kubernetes to deploy"
  type        = string
  default     = "1.32"
}

variable "aws_account_id" {
  description = "The AWS account ID"
  type        = string
}

variable "name_prefix" {
  description = "the prefix for the name which containts the environment and business unit"
  type        = string
}

variable "vpc_name" {
  description = "name of the vpc"
  type        = string
  default     = ""
}

