variable "environment" {
  description = "The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD"
}

variable "name" {
  description = "The name of the resource"
  default     = ""
}

variable "name_prefix" {
  description = "the environment and project"
}

