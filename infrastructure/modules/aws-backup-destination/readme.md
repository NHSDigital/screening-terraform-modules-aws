# AWS Backup Module

The AWS Backup Module helps automates the setup of AWS Backup resources in a destination account. It streamlines the process of creating, managing, and standardising backup configurations.

## Inputs

| Name                                                                                                                     | Description                                                                                                                                                                                         | Type           | Default                 | Required |
| ------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ----------------------- | :------: |
| <a name="input_account_id"></a> [account_id](#input_account_id)                                                          | The id of the account that the vault will be in                                                                                                                                                     | `string`       | n/a                     |   yes    |
| <a name="input_changeable_for_days"></a> [changeable_for_days](#input_changeable_for_days)                               | How long you want the vault lock to be changeable for, only applies to compliance mode. This value is expressed in days no less than 3 and no greater than 36,500; otherwise, an error will return. | `number`       | `14`                    |    no    |
| <a name="input_enable_vault_protection"></a> [enable_vault_protection](#input_enable_vault_protection)                   | Flag which controls if the vault lock is enabled                                                                                                                                                    | `bool`         | `false`                 |    no    |
| <a name="input_enable_iam_protection"></a> [enable_iam_protection](#input_enable_vault_protection)                       | Flag which controls if the vault iam is locked down, and copy restrictions are in place                                                                                                             | `bool`         | `false`                 |    no    |
| <a name="input_kms_key"></a> [kms_key](#input_kms_key)                                                                   | The KMS key used to secure the vault                                                                                                                                                                | `string`       | n/a                     |   yes    |
| <a name="input_name_prefix"></a> [name_prefix](#input_name_prefix)                                                       | Optional name prefix for vault resources                                                                                                                                                            | `string`       | `null`                  |    no    |
| <a name="input_region"></a> [region](#input_region)                                                                      | The region we should be operating in                                                                                                                                                                | `string`       | `"eu-west-2"`           |    no    |
| <a name="input_source_account_ids"></a> [source_account_ids](#input_source_account_ids)                                  | The ids of the accounts that backups will come from                                                                                                                                                 | `list(string)` | n/a                     |   yes    |
| <a name="input_source_account_name"></a> [source_account_name](#input_source_account_name)                               | The name of the account that backups will come from                                                                                                                                                 | `string`       | n/a                     |   yes    |
| <a name="input_vault_lock_max_retention_days"></a> [vault_lock_max_retention_days](#input_vault_lock_max_retention_days) | The maximum retention period required on recovery points when vault lock enabled                                                                                                                    | `number`       | `365`                   |    no    |
| <a name="input_vault_lock_min_retention_days"></a> [vault_lock_min_retention_days](#input_vault_lock_min_retention_days) | The minimum retention period required on recovery points when vault lock enabled                                                                                                                    | `number`       | `365`                   |    no    |
| <a name="input_vault_lock_type"></a> [vault_lock_type](#input_vault_lock_type)                                           | The type of lock that the vault should be, will default to governance                                                                                                                               | `string`       | `"governance"`          |    no    |
| <a name="input_source_vault_arn"></a> [source\vault_arn](#input_source_vault_arn)                                        | arn of the source vault, used to restrict where copies are allowed back to                                                                                                                          | `string`       | `"arn:aws:backup:blah"` |    no    |

## Example

```terraform
module "test_backup_vault" {
  source                  = "./modules/aws_backup"
  source_account_name     = "test"
  account_id              = local.aws_accounts_ids["backup"]
  source_account_ids      = [local.aws_accounts_ids["test"]]
  kms_key                 = aws_kms_key.backup_key.arn
  enable_vault_protection = true
}
```

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.47.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_backup_vault.vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_backup_vault_lock_configuration.vault_lock](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault_lock_configuration) | resource |
| [aws_backup_vault_policy.vault_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault_policy) | resource |
| [aws_iam_role.copy_recovery_point](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.copy_recovery_point_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_policy_document.copy_recovery_point_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.copy_recovery_point_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vault_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | The id of the account that the vault will be in | `string` | n/a | yes |
| <a name="input_changeable_for_days"></a> [changeable\_for\_days](#input\_changeable\_for\_days) | How long you want the vault lock to be changeable for, only applies to compliance mode. This value is expressed in days no less than 3 and no greater than 36,500; otherwise, an error will return. | `number` | `14` | no |
| <a name="input_enable_cross_account_vault_access"></a> [enable\_cross\_account\_vault\_access](#input\_enable\_cross\_account\_vault\_access) | Flag to enable cross account vault access for AWS Backup | `bool` | `false` | no |
| <a name="input_enable_vault_protection"></a> [enable\_vault\_protection](#input\_enable\_vault\_protection) | Flag which controls if the vault lock is enabled | `bool` | `false` | no |
| <a name="input_kms_key"></a> [kms\_key](#input\_kms\_key) | The KMS key used to secure the vault | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Optional name prefix for vault resources | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The region we should be operating in | `string` | `"eu-west-2"` | no |
| <a name="input_source_account_ids"></a> [source\_account\_ids](#input\_source\_account\_ids) | The ids of the accounts that backups will come from | `list(string)` | n/a | yes |
| <a name="input_source_account_name"></a> [source\_account\_name](#input\_source\_account\_name) | The name of the account that backups will come from | `string` | n/a | yes |
| <a name="input_source_vault_arn"></a> [source\_vault\_arn](#input\_source\_vault\_arn) | Source account vault arn, if set copies back are restricted to only this vault | `string` | `""` | no |
| <a name="input_vault_lock_max_retention_days"></a> [vault\_lock\_max\_retention\_days](#input\_vault\_lock\_max\_retention\_days) | The maximum retention period required on recovery points when vault lock enabled | `number` | `365` | no |
| <a name="input_vault_lock_min_retention_days"></a> [vault\_lock\_min\_retention\_days](#input\_vault\_lock\_min\_retention\_days) | The minimum retention period required on recovery points when vault lock enabled | `number` | `365` | no |
| <a name="input_vault_lock_type"></a> [vault\_lock\_type](#input\_vault\_lock\_type) | The type of lock that the vault should be, will default to governance | `string` | `"governance"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_copy_recovery_point_role_arn"></a> [copy\_recovery\_point\_role\_arn](#output\_copy\_recovery\_point\_role\_arn) | ARN of role to assume from source account lambda (set ASSUME\_ROLE\_ARN to this). Only present if enabled. |
| <a name="output_vault_arn"></a> [vault\_arn](#output\_vault\_arn) | n/a |
| <a name="output_vault_name"></a> [vault\_name](#output\_vault\_name) | The name of the backup vault. |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
