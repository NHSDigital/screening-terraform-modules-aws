variable "name_prefix" {
  description = "the prefix for the name which containts the environment and business unit"
  type        = string
}

variable "name" {
  description = "The name of the resource"
  type        = string
  default     = "-elasticache"
}

variable "environment" {
  description = "The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD"
  type        = string
}

variable "aws_account_id" {
  description = "The AWS account ID"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "The ID for the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "The subnets that will be used for elasticache, usually private"
  type        = list(string)
}

variable "s3_bucket_name" {
  description = "The s3 bucket that security-hub will use"
  type        = string
}
