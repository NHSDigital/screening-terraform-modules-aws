variable "name_prefix" {
  description = "the prefix standard"
  type        = string
}

variable "function_name" {
  description = "The name of the Lambda function"
  type        = string
  default     = "uk-forwarder"
}

variable "python_version" {
  description = "The Python version to use for the Lambda function"
  type        = string
}

variable "handler_prefix" {
  description = "The prefix for the Lambda handler function"
  type        = string
}

variable "function_description" {
  description = "The description for the Lambda function"
  type        = string
}

variable "environment" {
  description = "Values to set in the Lambda function environment"
  type        = map(string)
  default     = {}
}

variable "layers" {
  description = "List of Lambda Layer ARNs to attach to the function"
  type        = list(string)
  default     = []
}

variable "vpc_subnet_ids" {
  description = "List of VPC subnet IDs for the Lambda function"
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs for the Lambda function"
  type        = list(string)
  default     = []
}

variable "timeout" {
  description = "Timeout for the Lambda function in seconds"
  type        = number
  default     = 120
}
