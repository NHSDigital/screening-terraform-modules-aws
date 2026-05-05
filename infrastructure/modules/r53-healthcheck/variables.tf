variable environment {
  description = "the environment the healthcheck is deployed into"
}

variable name_prefix {
  description = "the name prefix for the healthcheck"
}


variable "sns_topic" {
  type        = string
  description = "Existing SNS topic in eu-west-2 for notifications"
}
