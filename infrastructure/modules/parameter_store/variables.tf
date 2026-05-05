####################################################################################
# BSS COMMON
####################################################################################

variable "name_prefix" {
  description = "The account, environment etc"
  type        = string
}

variable "environment" {
  description = "The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD"
  type        = string
}

variable "enable_cloudwatch_agent" {
  description = "Whether to create the CloudWatch Agent configuration parameter for ECS tasks"
  type        = bool
  default     = false
}

variable "cloudwatch_agent_config_json" {
  description = "The CloudWatch Agent configuration JSON for ECS tasks"
  type        = string
  default     = ""
}
