variable "waf_log_group_name" {
  description = "waf log group"
}

variable "waf_name" {
  description = "waf name"
}


variable "exclude_ip_set_name" {
  description = "Service"
}
variable "web_services_ip_set_name" {

}

variable "aws_account_id" {

}

variable "name_prefix" {

}

variable "aws_region" {

}

variable "webservices_ip_set_addresses" {
  description = "List of IP addresses for web services"
  type        = list(string)
}
variable "environment" {
  description = "Environment i.e prod, nonprod"
}

