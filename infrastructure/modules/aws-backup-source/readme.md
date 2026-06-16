# AWS Backup Module

The AWS Backup Module helps automates the setup of AWS Backup resources in a source account. It streamlines the process of creating, managing, and standardising backup configurations.

## Example

```terraform
module "test_aws_backup" {
  source = "./modules/aws-backup"

  environment_name                   = "environment_name"
  bootstrap_kms_key_arn              = kms_key[0].arn
  project_name                       = "testproject"
  reports_bucket                     = "compliance-reports"
  terraform_role_arn                 = data.aws_iam_role.terraform_role.arn
}
```

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.14 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.8.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.47.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_eventbridge"></a> [eventbridge](#module\_eventbridge) | terraform-aws-modules/eventbridge/aws | 4.3.0 |
| <a name="module_lambda_layer"></a> [lambda\_layer](#module\_lambda\_layer) | ../../modules/lambda-layer | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_backup_framework.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_framework) | resource |
| [aws_backup_plan.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_plan) | resource |
| [aws_backup_report_plan.backup_jobs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_report_plan) | resource |
| [aws_backup_report_plan.backup_restore_testing_jobs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_report_plan) | resource |
| [aws_backup_report_plan.copy_jobs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_report_plan) | resource |
| [aws_backup_report_plan.resource_compliance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_report_plan) | resource |
| [aws_backup_restore_testing_plan.backup_restore_testing_plan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_restore_testing_plan) | resource |
| [aws_backup_restore_testing_selection.backup_restore_testing_selection_rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_restore_testing_selection) | resource |
| [aws_backup_selection.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection) | resource |
| [aws_backup_vault.intermediary_vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_backup_vault.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_backup_vault_notifications.backup_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault_notifications) | resource |
| [aws_backup_vault_policy.vault_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault_policy) | resource |
| [aws_cloudwatch_event_rule.restore_testing_complete](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.restore_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.restore_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.iam_policy_for_lambda_copy_recovery_point](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.restore_validation_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.iam_for_lambda_copy_job](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.iam_for_lambda_copy_recovery_point](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.restore_validation_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.cross_account_iam_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_copy_recovery_point_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.restore](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.restore_validation_lambda_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.restore_validation_lambda_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.s3_backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.s3_restore](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.backup_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.aws_backup_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.backup_key_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_lambda_function.lambda_copy_recovery_point](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.restore_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.start_cross_account_copy_job_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.allow_eventbridge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.eventbridge_invoke_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_security_group.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_sns_topic.backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.aws_backup_notifications_email_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_vpc_security_group_egress_rule.lambda_egress_for_rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.lambda_egress_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.lambda_ingress_for_rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [archive_file.lambda_copy_recovery_point_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.lambda_restore_validation_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.start_cross_account_copy_job_lambda_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.allow_backup_to_sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.backup_key_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_copy_job_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vault_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_roles.roles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_roles) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [terraform_remote_state.rds_instance](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |
| [terraform_remote_state.vpc](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_api_endpoint"></a> [api\_endpoint](#input\_api\_endpoint) | API endpoint to send post build version notifications to | `string` | `""` | no |
| <a name="input_api_token"></a> [api\_token](#input\_api\_token) | API token to authenticate with the API endpoint | `string` | `""` | no |
| <a name="input_backup_copy_vault_account_id"></a> [backup\_copy\_vault\_account\_id](#input\_backup\_copy\_vault\_account\_id) | The account id of the destination backup vault for allowing restores back into the source account. | `string` | `""` | no |
| <a name="input_backup_copy_vault_arn"></a> [backup\_copy\_vault\_arn](#input\_backup\_copy\_vault\_arn) | The ARN of the destination backup vault for cross-account backup copies. | `string` | `""` | no |
| <a name="input_backup_plan_config_rds"></a> [backup\_plan\_config\_rds](#input\_backup\_plan\_config\_rds) | Configuration for backup plans with RDS | <pre>object({<br/>    enable              = bool<br/>    selection_tag       = string<br/>    selection_tag_value = optional(string)<br/>    selection_tags = optional(list(object({<br/>      key   = optional(string)<br/>      value = optional(string)<br/>    })))<br/>    compliance_resource_types = list(string)<br/>    restore_testing_overrides = optional(map(string))<br/>    validation_window_hours   = optional(number)<br/>    rules = optional(list(object({<br/>      name                     = string<br/>      schedule                 = string<br/>      completion_window        = optional(number)<br/>      enable_continuous_backup = optional(bool)<br/>      lifecycle = object({<br/>        delete_after       = number<br/>        cold_storage_after = optional(number)<br/>      })<br/>      copy_action = optional(object({<br/>        delete_after = optional(number)<br/>      }))<br/>    })))<br/>  })</pre> | <pre>{<br/>  "compliance_resource_types": [<br/>    "RDS"<br/>  ],<br/>  "enable": true,<br/>  "rules": [<br/>    {<br/>      "completion_window": 24,<br/>      "copy_action": {<br/>        "delete_after": 365<br/>      },<br/>      "lifecycle": {<br/>        "delete_after": 35<br/>      },<br/>      "name": "rds_daily_kept_5_weeks",<br/>      "schedule": "cron(0 0 * * ? *)"<br/>    },<br/>    {<br/>      "completion_window": 48,<br/>      "copy_action": {<br/>        "delete_after": 365<br/>      },<br/>      "lifecycle": {<br/>        "delete_after": 90<br/>      },<br/>      "name": "rds_weekly_kept_3_months",<br/>      "schedule": "cron(0 1 ? * SUN *)"<br/>    },<br/>    {<br/>      "completion_window": 72,<br/>      "copy_action": {<br/>        "delete_after": 365<br/>      },<br/>      "lifecycle": {<br/>        "cold_storage_after": 30,<br/>        "delete_after": 2555<br/>      },<br/>      "name": "rds_monthly_kept_7_years",<br/>      "schedule": "cron(0 2 1  * ? *)"<br/>    }<br/>  ],<br/>  "selection_tag": "BackupRDS",<br/>  "selection_tag_value": "True",<br/>  "selection_tags": [],<br/>  "validation_window_hours": 1<br/>}</pre> | no |
| <a name="input_bootstrap_kms_key_arn"></a> [bootstrap\_kms\_key\_arn](#input\_bootstrap\_kms\_key\_arn) | The ARN of the bootstrap KMS key used for encryption at rest of the SNS topic. | `string` | n/a | yes |
| <a name="input_deletion_allowed_principal_arns"></a> [deletion\_allowed\_principal\_arns](#input\_deletion\_allowed\_principal\_arns) | List of ARNs of principals allowed to delete backups. | `list(string)` | `null` | no |
| <a name="input_destination_vault_retention_period"></a> [destination\_vault\_retention\_period](#input\_destination\_vault\_retention\_period) | Retention period for recovery points made with the copy job lambda | `number` | `365` | no |
| <a name="input_enable_notifications"></a> [enable\_notifications](#input\_enable\_notifications) | Flag to enable backup notifications. | `bool` | `false` | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | The name of the environment where AWS Backup is configured. | `string` | n/a | yes |
| <a name="input_iam_role_permissions_boundary"></a> [iam\_role\_permissions\_boundary](#input\_iam\_role\_permissions\_boundary) | Optional permissions boundary ARN for backup role | `string` | `""` | no |
| <a name="input_lambda_copy_recovery_point_assume_role_arn"></a> [lambda\_copy\_recovery\_point\_assume\_role\_arn](#input\_lambda\_copy\_recovery\_point\_assume\_role\_arn) | ARN of role in destination account the lambda assumes to initiate the copy job (if required for cross-account). | `string` | `""` | no |
| <a name="input_lambda_copy_recovery_point_destination_vault_arn"></a> [lambda\_copy\_recovery\_point\_destination\_vault\_arn](#input\_lambda\_copy\_recovery\_point\_destination\_vault\_arn) | Destination vault ARN containing the recovery point to be copied back (the air-gapped vault). | `string` | `""` | no |
| <a name="input_lambda_copy_recovery_point_enable"></a> [lambda\_copy\_recovery\_point\_enable](#input\_lambda\_copy\_recovery\_point\_enable) | Flag to enable the copy recovery point lambda (copy recovery point from destination vault back to source). | `bool` | `false` | no |
| <a name="input_lambda_copy_recovery_point_max_wait_minutes"></a> [lambda\_copy\_recovery\_point\_max\_wait\_minutes](#input\_lambda\_copy\_recovery\_point\_max\_wait\_minutes) | Maximum number of minutes to wait for a copy job to reach a terminal state before returning running status. | `number` | `10` | no |
| <a name="input_lambda_copy_recovery_point_poll_interval_seconds"></a> [lambda\_copy\_recovery\_point\_poll\_interval\_seconds](#input\_lambda\_copy\_recovery\_point\_poll\_interval\_seconds) | Polling interval in seconds for copy job status checks. | `number` | `30` | no |
| <a name="input_lambda_copy_recovery_point_source_vault_arn"></a> [lambda\_copy\_recovery\_point\_source\_vault\_arn](#input\_lambda\_copy\_recovery\_point\_source\_vault\_arn) | Source vault ARN to which the recovery point will be copied back. | `string` | `""` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Name prefix for vault resources | `string` | `null` | no |
| <a name="input_nation"></a> [nation](#input\_nation) | The nation this environment is for (e.g. en, ni) | `string` | n/a | yes |
| <a name="input_notifications_sns_topic_arn"></a> [notifications\_sns\_topic\_arn](#input\_notifications\_sns\_topic\_arn) | The ARN of the SNS topic to use for backup notifications. | `string` | `""` | no |
| <a name="input_notifications_target_email_address"></a> [notifications\_target\_email\_address](#input\_notifications\_target\_email\_address) | The email address to which backup notifications will be sent via SNS. | `string` | `""` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | The name of the project this relates to. | `string` | n/a | yes |
| <a name="input_python_version"></a> [python\_version](#input\_python\_version) | The Python version to use for the Lambda function | `string` | `"3.12"` | no |
| <a name="input_reports_bucket"></a> [reports\_bucket](#input\_reports\_bucket) | Bucket to drop backup reports into | `string` | n/a | yes |
| <a name="input_restore_testing_db_name"></a> [restore\_testing\_db\_name](#input\_restore\_testing\_db\_name) | Name of the database to use for restore validation | `string` | n/a | yes |
| <a name="input_restore_testing_plan_algorithm"></a> [restore\_testing\_plan\_algorithm](#input\_restore\_testing\_plan\_algorithm) | Algorithm of the Recovery Selection Point | `string` | `"LATEST_WITHIN_WINDOW"` | no |
| <a name="input_restore_testing_plan_recovery_point_types"></a> [restore\_testing\_plan\_recovery\_point\_types](#input\_restore\_testing\_plan\_recovery\_point\_types) | Recovery Point Types | `list(string)` | <pre>[<br/>  "SNAPSHOT"<br/>]</pre> | no |
| <a name="input_restore_testing_plan_scheduled_expression"></a> [restore\_testing\_plan\_scheduled\_expression](#input\_restore\_testing\_plan\_scheduled\_expression) | Scheduled Expression of Recovery Selection Point | `string` | `"cron(0 1 ? * SUN *)"` | no |
| <a name="input_restore_testing_plan_selection_window_days"></a> [restore\_testing\_plan\_selection\_window\_days](#input\_restore\_testing\_plan\_selection\_window\_days) | Selection window days | `number` | `7` | no |
| <a name="input_restore_testing_plan_start_window"></a> [restore\_testing\_plan\_start\_window](#input\_restore\_testing\_plan\_start\_window) | Start window from the scheduled time during which the test should start | `number` | `1` | no |
| <a name="input_restore_validation_db_credentials_secret_name"></a> [restore\_validation\_db\_credentials\_secret\_name](#input\_restore\_validation\_db\_credentials\_secret\_name) | Name of the Secrets Manager secret containing database credentials for connectivity testing | `string` | n/a | yes |
| <a name="input_restore_validation_enable"></a> [restore\_validation\_enable](#input\_restore\_validation\_enable) | Enable automated validation of restored RDS instances during backup restore testing | `bool` | `false` | no |
| <a name="input_restore_validation_expected_subnet_pattern"></a> [restore\_validation\_expected\_subnet\_pattern](#input\_restore\_validation\_expected\_subnet\_pattern) | Expected pattern in the DB subnet group name for configuration validation | `string` | n/a | yes |
| <a name="input_restore_validation_log_retention_days"></a> [restore\_validation\_log\_retention\_days](#input\_restore\_validation\_log\_retention\_days) | Number of days to retain restore validation Lambda logs | `number` | `30` | no |
| <a name="input_restore_validation_timeout_seconds"></a> [restore\_validation\_timeout\_seconds](#input\_restore\_validation\_timeout\_seconds) | Timeout for the restore validation Lambda function in seconds | `number` | `300` | no |
| <a name="input_terraform_role_arn"></a> [terraform\_role\_arn](#input\_terraform\_role\_arn) | ARN of Terraform role used to deploy to account (deprecated, please swap to terraform\_role\_arns) | `string` | `""` | no |
| <a name="input_terraform_role_arns"></a> [terraform\_role\_arns](#input\_terraform\_role\_arns) | ARN of Terraform roles used to deploy to account, defaults to caller arn if list is empty | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_backup_role_arn"></a> [backup\_role\_arn](#output\_backup\_role\_arn) | ARN of the of the backup role |
| <a name="output_backup_vault_arn"></a> [backup\_vault\_arn](#output\_backup\_vault\_arn) | ARN of the of the vault |
| <a name="output_backup_vault_name"></a> [backup\_vault\_name](#output\_backup\_vault\_name) | Name of the of the vault |
| <a name="output_restore_validation_eventbridge_rule_name"></a> [restore\_validation\_eventbridge\_rule\_name](#output\_restore\_validation\_eventbridge\_rule\_name) | Name of the EventBridge rule that triggers restore validation |
| <a name="output_restore_validation_lambda_arn"></a> [restore\_validation\_lambda\_arn](#output\_restore\_validation\_lambda\_arn) | ARN of the restore validation Lambda function |
| <a name="output_restore_validation_lambda_name"></a> [restore\_validation\_lambda\_name](#output\_restore\_validation\_lambda\_name) | Name of the restore validation Lambda function |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
