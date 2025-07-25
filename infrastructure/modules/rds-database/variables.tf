variable "rds_name" {
  description = "the name of the service"
  type        = string
  default     = "postgres"
}

variable "environment" {
  description = "the environment the resource is deployed into"
  type        = string
}

variable "db_name" {
  description = "the name for the users database"
  type        = string
}

variable "name_prefix" {
  description = "The name prefix which includes environment and region details"
  type        = string
}
