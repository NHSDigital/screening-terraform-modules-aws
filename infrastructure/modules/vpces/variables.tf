# tflint-ignore: terraform_unused_declarations
variable "environment" {
  description = "The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD"
  type        = string
}

# tflint-ignore: terraform_unused_declarations
variable "nation" {
  description = "en for england or ni for northern ireland"
  type        = string
  default     = "en"
}

# tflint-ignore: terraform_unused_declarations
variable "prefix" {
  description = "The prefix to use for naming resources"
  type        = string
}


variable "vpces_name" {
  description = "The name of the VPC Endpoint Service"
  type        = string
}

variable "nlb_name" {
  description = "The name of the Network Load Balancer"
  type        = string
}

variable "tg_name" {
  description = "The name of the Target Group"
  type        = string
}


variable "vpc_id" {
  description = "The VPC ID where the VPC Endpoint Service will be created"
  type        = string

}

variable "subnet_ids" {
  description = "The Subnet IDs where the Network Load Balancer will be created"
  type        = list(string)
}

variable "alb_arn" {
  description = "The ARN of the ALB to target"
  type        = string

}

# tflint-ignore: terraform_unused_declarations
variable "alb_listener" {
  description = "The ARN of the ALB listener to target"
  type        = string
}

variable "allowed_principal_secret_name" {
  description = "The name of the Secrets Manager secret containing the AWS account ID allowed to use this VPCE service"
  type        = string
}

variable "target_alb_sg_id" {
  description = "The security group ID of the target ALB to allow inbound from the NLB"
  type        = string
}

variable "ssm_parameter_name" {
  description = "The name of the SSM parameter to store the allowed IPs"
  type        = string
}

variable "access_logs_bucket" {
  description = "The S3 bucket to store access logs"
  type        = string
}

variable "access_logs_prefix" {
  description = "The S3 prefix for access logs"
  type        = string
}
