# RDS-Database

<!-- vale off -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_postgresql"></a> [postgresql](#requirement_postgresql) | >= 1.25.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider_aws) | n/a |
| <a name="provider_postgresql"></a> [postgresql](#provider_postgresql) | >= 1.25.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [postgresql_database.my_db](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/database) | resource |
| [aws_db_instance.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/db_instance) | data source |
| [aws_secretsmanager_secret.release_manager_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret_version.release_manager_password_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_db_name"></a> [db_name](#input_db_name) | the name for the users database | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input_environment) | the environment the resource is deployed into | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name_prefix](#input_name_prefix) | The name prefix which includes environment and region details | `string` | n/a | yes |
| <a name="input_rds_name"></a> [rds_name](#input_rds_name) | the name of the service | `string` | `"postgres"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
<!-- vale on -->
