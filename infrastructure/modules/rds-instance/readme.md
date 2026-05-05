# RDS-Instance

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
| <a name="provider_random"></a> [random](#provider_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_db_instance.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_parameter_group.parameter_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group) | resource |
| [aws_db_subnet_group.private_bss](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_iam_policy.enhanced_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.enhanced_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.enhanced_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_secretsmanager_secret.password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.ecs_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [random_id.final_name](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.final-name](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allocated_storage"></a> [allocated_storage](#input_allocated_storage) | The amount of storage to allocate to the database in GB | `number` | `50` | no |
| <a name="input_allow_major_version_upgrade"></a> [allow_major_version_upgrade](#input_allow_major_version_upgrade) | Whether to allow major version upgrades to the database | `bool` | `false` | no |
| <a name="input_apply_immediately"></a> [apply_immediately](#input_apply_immediately) | Whether to apply changes to the database immediately | `bool` | `true` | no |
| <a name="input_auto_minor_version_upgrade"></a> [auto_minor_version_upgrade](#input_auto_minor_version_upgrade) | Whether to automatically upgrade the database to the latest minor version | `bool` | `true` | no |
| <a name="input_aws_account_id"></a> [aws_account_id](#input_aws_account_id) | The AWS account ID | `string` | n/a | yes |
| <a name="input_aws_secret_id"></a> [aws_secret_id](#input_aws_secret_id) | The name of the secret that holds the postgresql login details | `string` | n/a | yes |
| <a name="input_backup_retention_period"></a> [backup_retention_period](#input_backup_retention_period) | The number of days to retain automated backups for | `number` | `4` | no |
| <a name="input_backup_window"></a> [backup_window](#input_backup_window) | The time window to perform automated backups in UTC (HH:MM-HH:MM) | `string` | `"01:00-02:00"` | no |
| <a name="input_cloudwatch_log_retention_days"></a> [cloudwatch_log_retention_days](#input_cloudwatch_log_retention_days) | Number of days to retain CloudWatch logs | `number` | `7` | no |
| <a name="input_copy_tags_to_snapshot"></a> [copy_tags_to_snapshot](#input_copy_tags_to_snapshot) | Whether to copy tags to database snapshots | `bool` | `true` | no |
| <a name="input_database_insights_mode"></a> [database_insights_mode](#input_database_insights_mode) | Whether to set database insights mode to standard or advanced | `string` | n/a | yes |
| <a name="input_db_max_connections"></a> [db_max_connections](#input_db_max_connections) | how many connections are allowed | `number` | `5000` | no |
| <a name="input_db_storage_encryption"></a> [db_storage_encryption](#input_db_storage_encryption) | Whether the database storage should be encrypted | `bool` | `true` | no |
| <a name="input_deletion_protection"></a> [deletion_protection](#input_deletion_protection) | Whether to enable deletion protection for the database | `bool` | `false` | no |
| <a name="input_ecs_sg_id"></a> [ecs_sg_id](#input_ecs_sg_id) | The security group ID for the ECS service | `string` | n/a | yes |
| <a name="input_enable_backup"></a> [enable_backup](#input_enable_backup) | Whether to enable automated backups for the database | `bool` | `false` | no |
| <a name="input_enabled_cloudwatch_logs_exports"></a> [enabled_cloudwatch_logs_exports](#input_enabled_cloudwatch_logs_exports) | Which logs should be exported | `list(string)` | <pre>[<br/>  "postgresql"<br/>]</pre> | no |
| <a name="input_encryption"></a> [encryption](#input_encryption) | If encryption should be enabled | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input_environment) | The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD | `string` | n/a | yes |
| <a name="input_iops"></a> [iops](#input_iops) | specify the provisioned IOPS, cannot be used if gp3 storage allocation is below 400 | `number` | `3000` | no |
| <a name="input_is_temporary_shutdown"></a> [is_temporary_shutdown](#input_is_temporary_shutdown) | Whether the database is in a temporary shutdown state (not a standard AWS attribute) | `bool` | `false` | no |
| <a name="input_maintenance_window"></a> [maintenance_window](#input_maintenance_window) | The time window to perform maintenance on the database in UTC (Day:HH:MM-Day:HH:MM) | `string` | `"Tue:02:30-Tue:03:30"` | no |
| <a name="input_monitoring_interval"></a> [monitoring_interval](#input_monitoring_interval) | The interval in seconds to monitor the database | `number` | `10` | no |
| <a name="input_multi_az"></a> [multi_az](#input_multi_az) | Whether to deploy the database in multiple Availability Zones | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input_name) | The name of the resource | `any` | n/a | yes |
| <a name="input_name_prefix"></a> [name_prefix](#input_name_prefix) | The account, environment etc | `string` | n/a | yes |
| <a name="input_performance_insights_enabled"></a> [performance_insights_enabled](#input_performance_insights_enabled) | Whether to enable Performance Insights for the database | `bool` | `false` | no |
| <a name="input_performance_insights_retention_period"></a> [performance_insights_retention_period](#input_performance_insights_retention_period) | The number of days to retain Performance Insights data for | `number` | `7` | no |
| <a name="input_port"></a> [port](#input_port) | The port the database will listen on | `number` | `5432` | no |
| <a name="input_private_subnet_ids"></a> [private_subnet_ids](#input_private_subnet_ids) | A list of private subnets to use | `list(string)` | n/a | yes |
| <a name="input_publicly_accessible"></a> [publicly_accessible](#input_publicly_accessible) | Whether the database is publicly accessible | `bool` | `false` | no |
| <a name="input_rds_engine"></a> [rds_engine](#input_rds_engine) | The engine for the RDS instance | `string` | `"postgres"` | no |
| <a name="input_rds_engine_version"></a> [rds_engine_version](#input_rds_engine_version) | The engine version for the RDS instance | `string` | `"16"` | no |
| <a name="input_rds_instance_class"></a> [rds_instance_class](#input_rds_instance_class) | The instance class for the RDS instance | `string` | n/a | yes |
| <a name="input_recovery_window"></a> [recovery_window](#input_recovery_window) | The number of days that credentials should be retained for | `number` | n/a | yes |
| <a name="input_secret_replication_regions"></a> [secret_replication_regions](#input_secret_replication_regions) | List of additional regions where created secrets should be replicated | `list(string)` | n/a | yes |
| <a name="input_skip_final_snapshot"></a> [skip_final_snapshot](#input_skip_final_snapshot) | Should there be a snapshot taken when instance destroyed | `bool` | `false` | no |
| <a name="input_snapshot_identifier"></a> [snapshot_identifier](#input_snapshot_identifier) | Optional snapshot identifier to restore from (e.g. if on performance environent) | `string` | `""` | no |
| <a name="input_storage"></a> [storage](#input_storage) | The storage size for the instance | `string` | `100` | no |
| <a name="input_storage_type"></a> [storage_type](#input_storage_type) | The type of storage used, options are 'standard', 'gp2', 'gp3', 'io1' or 'io2' | `string` | `"gp3"` | no |
| <a name="input_tags"></a> [tags](#input_tags) | A map of tags to assign to the RDS instance in addition to the default tags | `map(string)` | `{}` | no |
| <a name="input_user"></a> [user](#input_user) | username for postgres instance to use | `string` | `"postgres"` | no |
| <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id) | The id for the vpc | `string` | n/a | yes |
| <a name="input_vpc_name"></a> [vpc_name](#input_vpc_name) | vpc name | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_rds_instance_address"></a> [rds_instance_address](#output_rds_instance_address) | Endpoint of the instance excluding port |
| <a name="output_rds_instance_arn"></a> [rds_instance_arn](#output_rds_instance_arn) | The ARN of the RDS instance |
| <a name="output_rds_instance_endpoint"></a> [rds_instance_endpoint](#output_rds_instance_endpoint) | The endpoint of the RDS instance including port |
| <a name="output_rds_instance_id"></a> [rds_instance_id](#output_rds_instance_id) | The ID of the RDS instance |
| <a name="output_rds_name"></a> [rds_name](#output_rds_name) | n/a |
| <a name="output_rds_sg_id"></a> [rds_sg_id](#output_rds_sg_id) | The security group ID for the RDS instance |
<!-- END_TF_DOCS -->
<!-- vale on -->
