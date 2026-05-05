# Github-config

<!-- vale off -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_github"></a> [github](#requirement_github) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_github"></a> [github](#provider_github) | ~> 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [github_actions_environment_secret.aws_account](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_secret) | resource |
| [github_repository_environment.repo_environment](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_environment) | resource |
| [github_repository.repo](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/repository) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_account_id"></a> [aws_account_id](#input_aws_account_id) | The AWS account ID | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input_environment) | The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD | `string` | n/a | yes |
| <a name="input_github_app_token"></a> [github_app_token](#input_github_app_token) | The GitHub App token used to authenticate with the GitHub provider | `string` | n/a | yes |
| <a name="input_github_repo_name"></a> [github_repo_name](#input_github_repo_name) | the name for the github repo | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
<!-- vale on -->
