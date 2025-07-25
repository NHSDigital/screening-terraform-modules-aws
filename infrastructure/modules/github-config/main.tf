terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  owner = "NHSDigital"
  app_auth {}
}

data "github_repository" "repo" {
  full_name = var.github_repo_name
}

resource "github_repository_environment" "repo_environment" {
  repository  = data.github_repository.repo.name
  environment = var.environment
}

resource "github_actions_environment_secret" "aws_account" {
  repository      = data.github_repository.repo.name
  environment     = github_repository_environment.repo_environment.environment
  secret_name     = "AWS_ACCOUNT_ID"
  plaintext_value = var.aws_account_id
}

# resource "github_actions_environment_variable" "tf_version" {
#   repository    = data.github_repository.repo.name
#   environment   = github_repository_environment.repo_environment.environment
#   variable_name = "TF_VERSION"
#   value         = var.terraform_version
# }
