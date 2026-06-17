# tflint-ignore: terraform_unused_declarations
variable "aws_account_id" {
  description = "AWS account ID for the deployment context"
  type        = string
}

variable "aws_lambda_name" {
  description = "Lambda function name"
  type        = string
}

variable "aws_lambda_arn" {
  description = "Lambda function ARN"
  type        = string
}

# tflint-ignore: terraform_unused_declarations
variable "aws_region" {
  description = "The AWS region where the API Gateway is deployed"
  type        = string
  default     = "eu-west-2"

}

variable "api_gateway_name" {
  description = "the name of the API Gateway"
  type        = string
}

variable "api_path_part" {
  description = "the url path for the API"
  type        = string
}

variable "stage_name" {
  description = "the API stage name"
  type        = string
}



variable "http_method" {
  description = "The HTTP method to use for the API Gateway"
  type        = string
}

variable "api_gateway_description" {
  description = "Description for the API Gateway"
  type        = string

}

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "hosted_zone_name" {
  description = "The hosted zone name for the custom domain"
  type        = string
}
variable "domain_name_prefix" {
  description = "Prefix for the custom domain name"
  type        = string
}

variable "route53_hosted_zone_id" {
  description = "The ID of the Route53 hosted zone"
  type        = string
}

variable "certificate_arn" {
  description = "The ARN of the ACM certificate to use for the custom domain (optional, will create if not provided)"
  type        = string
  default     = null
}

variable "secret_replication_regions" {
  description = "List of additional regions where created secrets should be replicated"
  type        = list(string)
}
