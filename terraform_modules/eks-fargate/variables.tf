variable "environment" {
  description = "The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD"
  type        = string
}

variable "name" {
  description = "The name of the resource"
  type        = string
}

variable "cluster_version" {
  description = "The version of kubernetes to deploy"
  type        = string
  default     = "1.32"
}

variable "account_id" {
  description = "The AWS account ID"
  type        = string
}

