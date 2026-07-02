# RDS Module

Thin NHS wrapper around [`terraform-aws-modules/rds/aws`](https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest) (v7.2.0).

The module provisions an RDS DB instance together with its subnet group, parameter group, option group, and (optionally) an Enhanced Monitoring IAM role. The caller is responsible for creating a security group (use the dedicated security group module) and passing its ID via `vpc_security_group_ids`.

## What this module enforces

|Control|Value|Reason|
|---|---|---|
|`publicly_accessible`|`false`|Databases must never be internet-facing|
|`storage_encrypted`|`true`|Encryption at rest is mandatory|
|`copy_tags_to_snapshot`|`true`|Snapshots must carry the same tags as the instance|
|`auto_minor_version_upgrade`|`false`|Teams keep instances in sync with the production engine version|
|`create_db_subnet_group`|`true`|subnet group is always managed by this module|
|`vpc_security_group_ids`|Non-empty list required|RDS must not rely on the default VPC security group; callers must always supply at least one explicit security group|
|`performance_insights_kms_key_id`|Required when Performance Insights enabled|AWS-managed keys are not acceptable per platform policy; a customer-managed KMS key must always be supplied|
|Creation gate|`module.this.enabled`|Prevents all managed RDS resources when disabled|

## Usage

### Minimal PostgreSQL instance

```hcl
module "postgres_rds" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws//infrastructure/modules/rds?ref=vX.Y.Z"

  service     = "bcss"
  project     = "screening"
  environment = "dev"
  stack       = "database"
  workspace   = terraform.workspace

  engine               = "postgres"
  engine_version       = "16"
  major_engine_version = "16"
  family               = "postgres16"

  instance_class    = "db.t4g.medium"
  allocated_storage = 100

  db_name  = "screening"
  username = var.rds_master_username
  port     = 5432

  password_wo         = var.rds_master_password
  password_wo_version = 1

  subnet_ids             = data.aws_subnets.private.ids
  vpc_security_group_ids = [module.rds_security_group.security_group_id]
}
```

### Oracle with a fresh database

```hcl
module "oracle_rds" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws//infrastructure/modules/rds?ref=vX.Y.Z"

  # context
  service     = var.service
  environment = var.environment
  workspace   = terraform.workspace

  # identity (optional)
  # If omitted, the module derives a name from context labels.
  identifier = "${var.name_prefix}-oracle-${var.environment}-${terraform.workspace}"

  # engine
  engine               = "oracle-ee"
  engine_version       = "19"
  license_model        = "license-included"
  major_engine_version = "19"
  family               = "oracle-ee-19"
  character_set_name   = "AL32UTF8"

  # sizing
  instance_class    = "db.m5.large"
  allocated_storage = 100
  storage_type      = "gp3"

  # database
  db_name  = "MYDB"
  username = var.rds_master_username
  port     = 1521

  # credentials (write-only — not stored in state)
  password_wo         = var.rds_master_password
  password_wo_version = 1

  # networking
  subnet_ids             = data.aws_subnets.private.ids
  vpc_security_group_ids = [module.rds_security_group.security_group_id]

  # options (Oracle S3 integration and timezone)
  options = [
    {
      option_name                    = "S3_INTEGRATION"
      version                        = "1.0"
      port                           = 0
      vpc_security_group_memberships = []
      option_settings                = []
    },
    {
      option_name                    = "Timezone"
      port                           = 0
      vpc_security_group_memberships = []
      option_settings = [
        { name = "TIME_ZONE", value = "Europe/London" }
      ]
    }
  ]

  # parameters
  parameters = [
    { name = "_add_col_optim_enabled", value = "TRUE", apply_method = "immediate" }
  ]

  # availability and backup
  multi_az                = var.environment == "prod" ? true : false
  backup_retention_period = 7
  skip_final_snapshot     = false
  deletion_protection     = var.environment == "prod" ? true : false
}
```

### Restore from snapshot

```hcl
module "oracle_rds" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws//infrastructure/modules/rds?ref=vX.Y.Z"

  # ... (same as above)

  # When restoring from a snapshot, character_set_name must be null
  character_set_name  = null
  snapshot_identifier = "rds:my-db-2024-01-01-06-00"
}
```

### RDS-managed password (no password in Terraform state)

```hcl
module "oracle_rds" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws//infrastructure/modules/rds?ref=vX.Y.Z"

  # ...

  manage_master_user_password = true
  # password_wo is not required when manage_master_user_password = true
}
```

### With security-group and secrets-manager modules

This example shows the recommended pattern for production use: integrating with the dedicated security-group and secrets-manager modules.

```hcl
# Create a security group using the NHS security-group wrapper module
module "rds_security_group" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws//infrastructure/modules/security-group?ref=vX.Y.Z""

  service     = "bcss"
  project     = "screening"
  environment = var.environment
  workspace   = terraform.workspace

  vpc_id      = data.aws_vpc.private.id
  description = "Security group for RDS database"

  # Allow inbound on Oracle port from application security group
  ingress_rules = [
    {
      from_port       = 1521
      to_port         = 1521
      protocol        = "tcp"
      security_groups = [module.app_security_group.security_group_id]
      description     = "Oracle from application"
    }
  ]
}

# Store the master password in Secrets Manager
module "rds_secret" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws//infrastructure/modules/secrets-manager?ref=vX.Y.Z"

  service     = "bcss"
  project     = "screening"
  environment = var.environment
  workspace   = terraform.workspace
  name        = "rds-master-password"

  secret_string = var.rds_master_password
  # Optionally: managed rotation, encryption key, tags, etc.
}

# Create the RDS instance with the security group and managed password
module "oracle_rds" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws//infrastructure/modules/rds?ref=vX.Y.Z"

  service     = "bcss"
  project     = "screening"
  environment = var.environment
  workspace   = terraform.workspace
  stack       = "database"

  engine               = "oracle-ee"
  engine_version       = "19"
  license_model        = "license-included"
  major_engine_version = "19"
  family               = "oracle-ee-19"
  character_set_name   = "AL32UTF8"

  instance_class    = "db.m5.large"
  allocated_storage = 500
  storage_type      = "gp3"

  db_name  = "MYDB"
  username = var.rds_master_username
  port     = 1521

  # Use RDS Secrets Manager integration for password management
  manage_master_user_password = true
  # The password is automatically stored in Secrets Manager by RDS
  # Retrieve it via module output: module.oracle_rds.master_user_secret_arn

  subnet_ids             = data.aws_subnets.private.ids
  # Pass the security group created above
  vpc_security_group_ids = [module.rds_security_group.security_group_id]

  multi_az                = var.environment == "prod"
  backup_retention_period = 7
  skip_final_snapshot     = false
  deletion_protection     = var.environment == "prod"

  depends_on = [module.rds_security_group]
}

# Output the secret arn for application connection strings
output "rds_secret_arn" {
  value       = module.rds_secret.secret_arn
  description = "arn of the RDS master password secret"
}

output "rds_endpoint" {
  value       = module.oracle_rds.instance_endpoint
  description = "RDS instance endpoint (host:port)"
}
```

The master password arn is exposed via the `master_user_secret_arn` output.

## Conventions

- Naming and tagging come from shared `context.tf` via `module.this`.
- Identifier resolution order is `identifier`, then `module.this.id`. If neither is set, the name is derived from context labels.
- Security groups are intentionally caller-managed. This module associates IDs passed via `vpc_security_group_ids`.
- Resource creation is gated by `module.this.enabled`.
- Snapshot tagging is always enabled via `copy_tags_to_snapshot = true`.
- Resource arn values (e.g., `instance_arn`) are exposed as output attributes.
- IAM authentication and resource tagging require the instance resource ID.

## What this module does NOT do

- Create or manage security groups.
- Allow public internet access to the database instance.
- Disable encryption at rest.
- Enable automatic minor engine upgrades.

## Migration from the local bcss `rds` module

When migrating from `../../modules/rds` in the bcss repo to this shared module, note:

1. **Output names** — `instance_endpoint`, `instance_address`, `instance_port`, and `rds_subnet_group` are compatible with the local module. `rds_security_group` is no longer an output — the caller now owns the security group resource.
2. **`snapshot_identifier`** — The local module used `""` as "no snapshot". This module uses `null`. Update the calling stack.
3. **`password_wo`** — The local module accepted `master_password` as a plain variable (stored in state). This module uses `password_wo` (write-only, not persisted in state).
4. **`deletion_protection`** — Defaults to `true` here (defaults to whatever `var.deletion_protection` was in the local module). Add `#checkov:skip=CKV_AWS_293` to the module call in non-production stacks.
5. **`ignore_changes` lifecycle** — The local module ignored `engine`, `engine_version`, `availability_zone`, `db_subnet_group_name`, and `storage_encrypted` on the `aws_db_instance`. These lifecycle rules are inside the community module and cannot be overridden from a wrapper. Raise this as a known limitation in the migration PR.

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.42 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_rds"></a> [rds](#module\_rds) | terraform-aws-modules/rds/aws | 7.2.0 |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_allocated_storage"></a> [allocated\_storage](#input\_allocated\_storage) | The allocated storage in gibibytes | `number` | n/a | yes |
| <a name="input_application_role"></a> [application\_role](#input\_application\_role) | The role the application is performing | `string` | `"General"` | no |
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | Apply modifications immediately rather than deferring to the next maintenance window | `bool` | `false` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_backup_retention_period"></a> [backup\_retention\_period](#input\_backup\_retention\_period) | Number of days to retain automated backups. Must be between 0 and 35 | `number` | `7` | no |
| <a name="input_backup_window"></a> [backup\_window](#input\_backup\_window) | Daily UTC time range for automated backups (e.g. '23:00-23:30'). Must not overlap with maintenance\_window | `string` | `"23:00-23:30"` | no |
| <a name="input_character_set_name"></a> [character\_set\_name](#input\_character\_set\_name) | Oracle character set name. Cannot be changed after creation. Must be null when restoring from a snapshot | `string` | `null` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "project": null,<br/>  "regex_replace_chars": null,<br/>  "region": null,<br/>  "service": null,<br/>  "stack": null,<br/>  "tags": {},<br/>  "terraform_source": null,<br/>  "workspace": null<br/>}</pre> | no |
| <a name="input_custom_name"></a> [custom\_name](#input\_custom\_name) | Optional override name for the RDS instance. Takes precedence over identifier when set. | `string` | `null` | no |
| <a name="input_data_classification"></a> [data\_classification](#input\_data\_classification) | Used to identify the data classification of the resource, e.g 1-5 | `string` | `"n/a"` | no |
| <a name="input_data_type"></a> [data\_type](#input\_data\_type) | The tag data\_type | `string` | `"None"` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | The name of the database to create. Omit to skip initial database creation | `string` | `null` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Prevents the DB instance from being deleted when true. Should be true in production | `bool` | `true` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>    format = string<br/>    labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_engine"></a> [engine](#input\_engine) | The database engine to use (e.g. 'oracle-ee', 'postgres', 'mysql') | `string` | n/a | yes |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | The engine version to use | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_family"></a> [family](#input\_family) | DB parameter group family (e.g. 'oracle-ee-19', 'postgres16', 'mysql8.0') | `string` | n/a | yes |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | Explicit name for the RDS instance. If null, this module derives the name from context labels. | `string` | `null` | no |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | The instance type of the RDS instance (e.g. 'db.m5.large') | `string` | n/a | yes |
| <a name="input_iops"></a> [iops](#input\_iops) | Provisioned IOPS. Required when storage\_type is 'io1' or 'io2' | `number` | `null` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | ARN of the KMS key for storage encryption. If omitted, the default account KMS key is used | `string` | `null` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_license_model"></a> [license\_model](#input\_license\_model) | License model for the DB instance. Required for some engines (e.g. Oracle SE1 requires 'license-included') | `string` | `null` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | Weekly maintenance window (e.g. 'Sun:00:00-Sun:03:00') | `string` | `"Sun:00:00-Sun:03:00"` | no |
| <a name="input_major_engine_version"></a> [major\_engine\_version](#input\_major\_engine\_version) | Major engine version for the option group (e.g. '19' for Oracle 19c) | `string` | n/a | yes |
| <a name="input_manage_master_user_password"></a> [manage\_master\_user\_password](#input\_manage\_master\_user\_password) | When true, RDS manages the master password in Secrets Manager. When false, password\_wo must be provided | `bool` | `false` | no |
| <a name="input_max_allocated_storage"></a> [max\_allocated\_storage](#input\_max\_allocated\_storage) | Upper limit for storage autoscaling in gibibytes. Set to 0 to disable autoscaling | `number` | `0` | no |
| <a name="input_monitoring_interval"></a> [monitoring\_interval](#input\_monitoring\_interval) | Interval in seconds between Enhanced Monitoring data points. Valid values: 0, 1, 5, 10, 15, 30, 60. Set to 0 to disable | `number` | `5` | no |
| <a name="input_multi_az"></a> [multi\_az](#input\_multi\_az) | Specifies if the RDS instance is Multi-AZ | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_on_off_pattern"></a> [on\_off\_pattern](#input\_on\_off\_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_options"></a> [options](#input\_options) | List of option group options to apply. See the community module documentation for the full object shape | `any` | `[]` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_parameters"></a> [parameters](#input\_parameters) | List of DB parameters to apply to the parameter group | <pre>list(object({<br/>    name         = string<br/>    value        = string<br/>    apply_method = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_password_wo"></a> [password\_wo](#input\_password\_wo) | Write-only password for the master DB user. Required when manage\_master\_user\_password is false and snapshot\_identifier is not set | `string` | `null` | no |
| <a name="input_password_wo_version"></a> [password\_wo\_version](#input\_password\_wo\_version) | Increment this value to trigger a password rotation when password\_wo changes | `number` | `1` | no |
| <a name="input_performance_insights_enabled"></a> [performance\_insights\_enabled](#input\_performance\_insights\_enabled) | Enable Performance Insights | `bool` | `true` | no |
| <a name="input_performance_insights_kms_key_id"></a> [performance\_insights\_kms\_key\_id](#input\_performance\_insights\_kms\_key\_id) | ARN of the KMS key used to encrypt Performance Insights data. If omitted, the default KMS key is used | `string` | `null` | no |
| <a name="input_performance_insights_retention_period"></a> [performance\_insights\_retention\_period](#input\_performance\_insights\_retention\_period) | Retention period for Performance Insights data in days. Valid values: 7, 731, or a multiple of 31 | `number` | `7` | no |
| <a name="input_port"></a> [port](#input\_port) | The port on which the DB accepts connections | `number` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_skip_final_snapshot"></a> [skip\_final\_snapshot](#input\_skip\_final\_snapshot) | If true, no final snapshot is created on deletion. Should be false in production | `bool` | `false` | no |
| <a name="input_snapshot_identifier"></a> [snapshot\_identifier](#input\_snapshot\_identifier) | Snapshot ID to restore the instance from. When set, character\_set\_name must be null | `string` | `null` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | One of 'standard', 'gp2', 'gp3', 'io1', or 'io2'. Defaults to 'io1' when iops is set, otherwise 'gp2' | `string` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of VPC subnet IDs for the DB subnet group | `list(string)` | n/a | yes |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to this module path. | `string` | `null` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Terraform resource management timeouts for the DB instance | <pre>object({<br/>    create = optional(string)<br/>    update = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_username"></a> [username](#input\_username) | Username for the master DB user | `string` | n/a | yes |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | List of security group IDs to associate with the instance. Create the security group using the dedicated security group module and pass its ID here | `list(string)` | `[]` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_db_option_group_id"></a> [db\_option\_group\_id](#output\_db\_option\_group\_id) | ID of the DB option group |
| <a name="output_db_parameter_group_id"></a> [db\_parameter\_group\_id](#output\_db\_parameter\_group\_id) | ID of the DB parameter group |
| <a name="output_db_subnet_group_id"></a> [db\_subnet\_group\_id](#output\_db\_subnet\_group\_id) | Name/ID of the DB subnet group |
| <a name="output_enhanced_monitoring_iam_role_arn"></a> [enhanced\_monitoring\_iam\_role\_arn](#output\_enhanced\_monitoring\_iam\_role\_arn) | ARN of the Enhanced Monitoring IAM role. Empty when monitoring\_interval is 0 |
| <a name="output_instance_address"></a> [instance\_address](#output\_instance\_address) | Hostname of the RDS instance (without port) |
| <a name="output_instance_arn"></a> [instance\_arn](#output\_instance\_arn) | ARN of the RDS instance |
| <a name="output_instance_endpoint"></a> [instance\_endpoint](#output\_instance\_endpoint) | Connection endpoint for the RDS instance in host:port format |
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | Identifier of the RDS instance |
| <a name="output_instance_port"></a> [instance\_port](#output\_instance\_port) | Port on which the RDS instance accepts connections |
| <a name="output_instance_resource_id"></a> [instance\_resource\_id](#output\_instance\_resource\_id) | The RDS resource ID (used for IAM authentication and tagging) |
| <a name="output_master_user_secret_arn"></a> [master\_user\_secret\_arn](#output\_master\_user\_secret\_arn) | ARN of the Secrets Manager secret for the master user password. Only populated when manage\_master\_user\_password is true |
| <a name="output_rds_subnet_group"></a> [rds\_subnet\_group](#output\_rds\_subnet\_group) | The DB subnet group used by the RDS instance, with id and arn attributes |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
