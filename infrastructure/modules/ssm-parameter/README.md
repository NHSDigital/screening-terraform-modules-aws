# SSM Parameter

Thin NHS wrapper around the community
[`terraform-aws-modules/ssm-parameter/aws`](https://registry.terraform.io/modules/terraform-aws-modules/ssm-parameter/aws/latest)
module that enforces the screening platform's baseline controls for parameter naming, tagging, and encryption.

## What this module enforces

| Control | How it is enforced | Impact |
| --- | --- | --- |
| Naming consistency | Parameter name is derived from context labels; path-style names always start with `/` | Ensures hierarchical organisation across teams |
| Tagging consistency | All tags sourced from `module.this.tags` (NHS-standard set) | Ensures billing, compliance, and governance controls |
| KMS encryption for secrets | `key_id` is **mandatory** when `type = "SecureString"` | No unencrypted secrets in SSM; prevents accidental exposure |
| Sensitive value protection | `value` and `values` marked `sensitive = true` in Terraform | Prevents secrets from appearing in logs/state diffs |
| Creation gating | `create = module.ssm_param_label.enabled` | Allows disabling entire module via context |

## Usage

### 1. Minimal string parameter

```hcl
module "app_config_parameter" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/ssm-parameter?ref=<tag>"

  context     = module.this.context
  stack       = "api"
  name        = "log-level"

  type  = "String"
  value = "INFO"
}
```

### 2. JSON-encoded SecureString parameter with KMS encryption (production)

Stores structured secrets (e.g., database credentials) encrypted with a customer-managed KMS key:

```hcl
module "database_credentials" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/ssm-parameter?ref=<tag>"

  context     = module.this.context
  stack       = "database"
  name        = "credentials"

  type   = "SecureString"
  key_id = module.kms.key_arn  # Required — KMS key is mandatory for SecureString

  # Store structured secrets as JSON — safer than flat strings
  value = jsonencode({
    engine   = "postgres"
    host     = module.rds.endpoint
    port     = 5432
    username = "admin"
    password = var.db_admin_password  # Use var with sensitive = true
  })

  description = "RDS Aurora credentials (JSON format)"
}
```

Output usage in consumer stack:

```hcl
locals {
  db_creds = jsondecode(module.ssm.parameter_value)
}

resource "aws_db_instance" "main" {
  db_name  = "screening_db"
  username = local.db_creds.username
  password = local.db_creds.password
  # ...
}
```

### 3. API key as SecureString

```hcl
module "third_party_api_key" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/ssm-parameter?ref=<tag>"

  context     = module.this.context
  stack       = "integration"
  name        = "third-party-api-key"

  type   = "SecureString"
  key_id = module.kms.key_arn

  value = var.api_key  # Passed from vars with sensitive = true
  description = "API key for third-party supplier integration (encrypted with KMS)"

  # Set to true when rotation Lambda updates the value outside Terraform
  ignore_value_changes = true
}
```

### 4. StringList parameter (comma-separated values)

```hcl
module "allowed_ip_addresses" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/ssm-parameter?ref=<tag>"

  context     = module.this.context
  stack       = "security"
  name        = "allowed-ips"

  type   = "StringList"
  values = ["10.0.0.0/8", "192.168.0.0/16"]  # Will be JSON-encoded by upstream module

  description = "Allowed source IP ranges for VPN/bastion access"
}
```

### 5. Parameter with external value management (Secrets Rotation)

When a rotation Lambda manages the secret value outside Terraform:

```hcl
module "rotated_api_secret" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/ssm-parameter?ref=<tag>"

  context     = module.this.context
  stack       = "integration"
  name        = "rotated-secret"

  type   = "SecureString"
  key_id = module.kms.key_arn

  value = var.initial_secret_value

  # Prevent Terraform from overwriting rotated values on apply
  ignore_value_changes = true

  description = "API secret that is auto-rotated every 30 days by Lambda"
}
```

### 6. Path-style hierarchical parameter

Store related configuration under a hierarchical path:

```hcl
module "app_database_config" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/ssm-parameter?ref=<tag>"

  context     = module.this.context
  stack       = "application"
  name        = "database/connection"  # Results in: /<service>/<project>/<environment>/<stack>/database/connection

  type  = "String"
  value = jsonencode({
    pool_size   = 10
    timeout     = 30
    retry_count = 3
  })

  description = "Application database connection pool configuration"
}
```

### 7. Write-only parameter (never stored in Terraform state)

For production secrets where state exposure is a compliance risk:

```hcl
module "production_secret" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/ssm-parameter?ref=<tag>"

  context     = module.this.context
  stack       = "production"
  name        = "api-secret"

  type   = "SecureString"
  key_id = module.kms.key_arn

  # Use value_wo_version instead of value — secret is never stored in Terraform state
  # Increment value_wo_version whenever the secret value changes to force Terraform to update
  value_wo_version = timestamp()  # or use a counter: var.secret_version_counter

  description = "Production API secret (never stored in state)"
}
```

## Conventions

- **Naming:** Parameter names are derived from context labels (`<service>/<project>/<environment>/<stack>/<name>`). All names are fully qualified starting with `/`. Override with `parameter_name` if custom naming is required.
- **Type selection:**
  - `String` — for plaintext configuration (URLs, counts, feature flags, etc.)
  - `StringList` — for comma-separated lists; the module JSON-encodes the values for you
  - `SecureString` — for sensitive values (passwords, API keys, tokens); **requires `key_id`**
- **SecureString encryption (MANDATORY):** When `type = "SecureString"`, you **must** provide a `key_id` (KMS key ARN or ID). This is enforced at `terraform plan` time and prevents unencrypted secrets.
- **Sensitive values:** Use Terraform variables with `sensitive = true` when passing secret values:

  ```hcl
  variable "db_password" {
    type      = string
    sensitive = true
  }
  ```

- **External value management:** Set `ignore_value_changes = true` when values are rotated by Lambda or other automation. This prevents Terraform from reverting externally-updated values on `apply`.
- **Write-only secrets:** Use `value_wo_version` (instead of `value`) for compliance-sensitive deployments where secrets must never be stored in Terraform state. Increment the trigger value to force updates.

## What this module does NOT do

- **Create KMS keys:** Provide an existing key ARN/ID via `key_id` for `SecureString` parameters; create keys separately using the `kms` module.
- **Manage parameter policies:** IAM policy attachment, resource-based policies, or access controls are caller responsibility.
- **Rotate secrets automatically:** Configure rotation using `aws_ssm_parameter` + Lambda directly in consumer stacks if needed. Set `ignore_value_changes = true` to prevent Terraform conflicts.
- **Resolve secrets from external systems:** The caller must explicitly provide `value`, `values`, or `value_wo_version` — no automatic fetching from Vault, Secrets Manager, or other sources.
- **Create IAM permissions:** Attach policies to roles/users who need to read/write parameters; this module creates the parameter only.
- **Share parameters across AWS accounts:** SSM parameters are account-scoped; use AWS Secrets Manager for cross-account sharing or cross-stack references.

## Validation

The following constraints are enforced at `plan` time and prevent invalid configurations before any resources are created:

### Variable-Level Validation

- **Type validation:** `type` must be `String`, `StringList`, or `SecureString` (enforced in variables.tf)
- **KMS key requirement:** When `type = "SecureString"`, `key_id` is mandatory (enforced in variables.tf)
- **Parameter name format:** `parameter_name` must start with `/` if overridden (enforced in variables.tf)

### Cross-Variable Validation (enforced in validations.tf)

- **Value mutual exclusivity:** Cannot set both `value` and `values` at the same time — specify only one source
- **Write-only scope:** `value_wo_version` (version trigger) is only valid when `type = "SecureString"`
- **Required value source:** At least one of `value`, `values`, or `value_wo_version` must be provided (cannot omit all three)
- **At least one value source**: One of `value`, `values`, or `value_wo_version` must be provided. Using all three is invalid.

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.28 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_ssm_param_label"></a> [ssm\_param\_label](#module\_ssm\_param\_label) | ../tags | n/a |
| <a name="module_ssm_parameter"></a> [ssm\_parameter](#module\_ssm\_parameter) | terraform-aws-modules/ssm-parameter/aws | 2.1.0 |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [terraform_data.validations](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_allowed_pattern"></a> [allowed\_pattern](#input\_allowed\_pattern) | Regular expression used to validate the parameter value | `string` | `null` | no |
| <a name="input_application_role"></a> [application\_role](#input\_application\_role) | The role the application is performing | `string` | `"General"` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "project": null,<br/>  "regex_replace_chars": null,<br/>  "region": null,<br/>  "service": null,<br/>  "stack": null,<br/>  "tags": {},<br/>  "terraform_source": null,<br/>  "workspace": null<br/>}</pre> | no |
| <a name="input_data_classification"></a> [data\_classification](#input\_data\_classification) | Used to identify the data classification of the resource, e.g 1-5 | `string` | `"n/a"` | no |
| <a name="input_data_type"></a> [data\_type](#input\_data\_type) | The tag data\_type | `string` | `"None"` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the parameter | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>    format = string<br/>    labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_ignore_value_changes"></a> [ignore\_value\_changes](#input\_ignore\_value\_changes) | Whether to create SSM Parameter and ignore changes in value | `bool` | `false` | no |
| <a name="input_key_id"></a> [key\_id](#input\_key\_id) | KMS key ID or ARN for encrypting a `SecureString` | `string` | `null` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_on_off_pattern"></a> [on\_off\_pattern](#input\_on\_off\_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_overwrite"></a> [overwrite](#input\_overwrite) | Overwrite an existing parameter. If not specified, defaults to `false` during create operations to avoid overwriting existing resources and then `true` for all subsequent operations once the resource is managed by Terraform | `bool` | `null` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_parameter_name"></a> [parameter\_name](#input\_parameter\_name) | Optional override for the full SSM parameter name (e.g., `/bcss/prod/myapp/config`). When provided, this takes precedence over the context-derived name. If not specified, the parameter name is derived from context as `/<service>/<project>/<environment>/<stack>/<name>`. | `string` | `null` | no |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_ssm_data_type"></a> [ssm\_data\_type](#input\_ssm\_data\_type) | Data type of the parameter. Valid values: `text`, `aws:ssm:integration` and `aws:ec2:image` for AMI format, see https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-ec2-aliases.html | `string` | `null` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to this module path. | `string` | `null` | no |
| <a name="input_tier"></a> [tier](#input\_tier) | Parameter tier to assign to the parameter. If not specified, will use the default parameter tier for the region. Valid tiers are Standard, Advanced, and Intelligent-Tiering. Downgrading an Advanced tier parameter to Standard will recreate the resource | `string` | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_type"></a> [type](#input\_type) | Type of the parameter. Valid types are `String`, `StringList` and `SecureString` | `string` | n/a | yes |
| <a name="input_value"></a> [value](#input\_value) | Value of the parameter. Can contain secrets such as database passwords or API keys. | `string` | `null` | no |
| <a name="input_value_wo_version"></a> [value\_wo\_version](#input\_value\_wo\_version) | Value of the parameter. This value is always marked as sensitive in the Terraform plan output, regardless of type. Additionally, write-only values are never stored to state. `value_wo_version` can be used to trigger an update and is required with this argument | `number` | `null` | no |
| <a name="input_values"></a> [values](#input\_values) | List of values of the parameter (will be jsonencoded to store as string natively in SSM). Can contain secrets. | `list(string)` | `[]` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_insecure_value"></a> [insecure\_value](#output\_insecure\_value) | Insecure value of the parameter |
| <a name="output_raw_value"></a> [raw\_value](#output\_raw\_value) | Raw value of the parameter (as it is stored in SSM). Use 'value' output to get jsondecode'd value |
| <a name="output_secure_type"></a> [secure\_type](#output\_secure\_type) | Whether SSM parameter is a SecureString or not? |
| <a name="output_secure_value"></a> [secure\_value](#output\_secure\_value) | Secure value of the parameter |
| <a name="output_ssm_parameter_arn"></a> [ssm\_parameter\_arn](#output\_ssm\_parameter\_arn) | The ARN of the parameter |
| <a name="output_ssm_parameter_name"></a> [ssm\_parameter\_name](#output\_ssm\_parameter\_name) | Name of the parameter |
| <a name="output_ssm_parameter_type"></a> [ssm\_parameter\_type](#output\_ssm\_parameter\_type) | Type of the parameter |
| <a name="output_ssm_parameter_version"></a> [ssm\_parameter\_version](#output\_ssm\_parameter\_version) | Version of the parameter |
| <a name="output_value"></a> [value](#output\_value) | Parameter value after jsondecode(). Probably this is what you are looking for |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
