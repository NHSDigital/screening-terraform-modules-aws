# tflint-ignore: terraform_unused_declarations
variable "environment" {
  description = "The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD"
  type        = string
}

# tflint-ignore: terraform_unused_declarations
variable "name" {
  description = "The name of the resource"
  type        = string
  default     = ""
}

variable "name_prefix" {
  description = "the environment and project"
  type        = string
}

variable "vpc_cidr_prefix" {
  description = "The CIDR block prefix for the VPC"
  type        = string
}
