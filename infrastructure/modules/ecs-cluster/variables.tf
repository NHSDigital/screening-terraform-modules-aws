variable "name_prefix" {
  description = "The account, environment etc"
  type        = string
}

variable "aws_account_id" {
  sensitive   = true
  description = "The AWS account ID"
  type        = string
}

variable "name" {
  default     = "ecs"
  description = "the unique name of the resource"
  type        = string
}

variable "container_port" {
  default = 4000
}


variable "vpc_id" {
  description = "id of the vpc"
  type        = string
}

variable "environment" {
  description = "The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD"
  type        = string
}
