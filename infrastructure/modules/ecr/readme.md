# ECR

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.49.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_ecr_lifecycle_policy.ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.image_repository](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository_policy.ecr_repo_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ecr_lifecycle_policy_document.ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecr_lifecycle_policy_document) | data source |
| [aws_iam_policy_document.ecr_repo_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_secretsmanager_secret.aws_account_ids](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret_version.aws_account_ids](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_developer_sso_role"></a> [developer\_sso\_role](#input\_developer\_sso\_role) | The SSO role for developers | `string` | n/a | yes |
| <a name="input_lifecycle_rules"></a> [lifecycle\_rules](#input\_lifecycle\_rules) | List of lifecycle rules. Each rule must be an object:<br/>{<br/>  priority    = number<br/>  description = string<br/>  selection = {<br/>    tag\_status       = string<br/>    tag\_prefix\_list  = optional(list(string))<br/>    tag\_pattern\_list = optional(list(string))<br/>    count\_type       = string<br/>    count\_number     = number<br/>    count\_unit       = optional(string)<br/>  }<br/>} | <pre>list(object({<br/>    priority    = number<br/>    description = string<br/>    selection = object({<br/>      tag_status       = string<br/>      tag_prefix_list  = optional(list(string))<br/>      tag_pattern_list = optional(list(string))<br/>      count_type       = string<br/>      count_number     = number<br/>      count_unit       = optional(string)<br/>    })<br/>  }))</pre> | `[]` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | The account, environment etc | `string` | n/a | yes |
| <a name="input_repo_name"></a> [repo\_name](#input\_repo\_name) | The name of the ECR repository | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
