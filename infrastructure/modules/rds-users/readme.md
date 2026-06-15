# RDS-Instance

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_postgresql"></a> [postgresql](#requirement\_postgresql) | >= 1.25.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.49.0 |
| <a name="provider_postgresql"></a> [postgresql](#provider\_postgresql) | 1.26.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_secretsmanager_secret.password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [postgresql_role.audit_user_role](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/role) | resource |
| [postgresql_role.bss_readonly_role](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/role) | resource |
| [postgresql_role.bss_readwrite_role](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/role) | resource |
| [postgresql_role.bss_user_role](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/role) | resource |
| [postgresql_role.pi_4_user_role](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/role) | resource |
| [postgresql_role.release_manager_role](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/role) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | The account, environment etc | `string` | n/a | yes |
| <a name="input_rds_endpoint"></a> [rds\_endpoint](#input\_rds\_endpoint) | The endpoint to connect to the rds instance | `string` | n/a | yes |
| <a name="input_rds_engine_version"></a> [rds\_engine\_version](#input\_rds\_engine\_version) | The engine version for the RDS instance | `string` | `"12.5"` | no |
| <a name="input_rds_password"></a> [rds\_password](#input\_rds\_password) | the password to login to rds with | `string` | n/a | yes |
| <a name="input_recovery_window"></a> [recovery\_window](#input\_recovery\_window) | The number of days that credentials should be retained for | `number` | n/a | yes |
| <a name="input_secret_replication_regions"></a> [secret\_replication\_regions](#input\_secret\_replication\_regions) | List of additional regions where created secrets should be replicated | `list(string)` | `[]` | no |
| <a name="input_users"></a> [users](#input\_users) | List of usernames to generate passwords and secrets for | `list(string)` | <pre>[<br/>  "pi_4_user",<br/>  "bss_user",<br/>  "bss_readwrite",<br/>  "bss_readonly",<br/>  "audit_user",<br/>  "release_manager"<br/>]</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bss_user_secret_arn"></a> [bss\_user\_secret\_arn](#output\_bss\_user\_secret\_arn) | n/a |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
