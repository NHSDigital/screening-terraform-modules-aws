variable "waf_log_group_name" {
  description = "waf log group"
  type        = string
}

variable "waf_name" {
  description = "waf name"
  type        = string
}


variable "exclude_ip_set_name" {
  description = "Service"
  type        = string
}

variable "web_services_ip_set_name" {
  description = "Name of the IP set for web service source addresses."
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID used in IAM and logging integrations."
  type        = string
}

variable "name_prefix" {
  description = "Prefix used for naming related resources."
  type        = string
}

variable "aws_region" {
  description = "AWS region where WAF resources are deployed."
  type        = string
}

# tflint-ignore: terraform_unused_declarations
variable "webservices_ip_set_addresses" {
  description = "List of IP addresses for web services"
  type        = list(string)
}

variable "environment" {
  description = "Environment i.e prod, nonprod"
  type        = string
}
