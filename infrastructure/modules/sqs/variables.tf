######################
# Common
######################

variable "name_prefix" {
  description = "The account, environment etc"
  type        = string
}

######################
# Module
######################

variable "stack_name" {
  description = "Name of stack calling the module to use in resource naming"
  type        = string
}

variable "topic_arn" {
  description = "Source SNS topic arn"
  type        = string
}
