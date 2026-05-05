variable "environment" {
  description = "The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD"
  type        = string
}

variable "aws_account_id" {
  description = "The AWS account ID"
  type        = string
  sensitive   = true
}

variable "github_repo_name" {
  description = "the name for the github repo"
  type        = string
}

variable "github_app_token" {
  description = "The GitHub App token used to authenticate with the GitHub provider"
  type        = string
  sensitive   = true
}
