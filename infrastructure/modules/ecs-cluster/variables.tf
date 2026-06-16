variable "name_prefix" {
  description = "The account, environment etc"
  type        = string
}

# tflint-ignore: terraform_unused_declarations
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

# tflint-ignore: terraform_unused_declarations
variable "container_port" {
  description = "Container port for ECS workloads"
  type        = number
  default     = 4000
}


variable "vpc_id" {
  description = "id of the vpc"
  type        = string
}

# tflint-ignore: terraform_unused_declarations
variable "environment" {
  description = "The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD"
  type        = string
}

variable "create_ecs_service_role" {
  description = "The service role can only be created once per account, only enable it in one stack"
  type        = bool
  default     = true
}
