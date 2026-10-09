# SSM Parameter (write-only)

Native NHS module for `aws_ssm_parameter` that keeps `SecureString` values out of Terraform state and plan files.
It sends secrets through the provider's write-only `value_wo` argument and accepts **ephemeral** values, such as those from `ephemeral` resources.

Use this module instead of [`ssm-parameter`](../ssm-parameter) when a secret must never be persisted by Terraform.
It declares `aws_ssm_parameter` directly because the community `terraform-aws-modules/ssm-parameter` module declares its `value` input as a normal (non-ephemeral) variable, so ephemeral values cannot pass through it.

## What this module enforces

| Control | How it is enforced | Impact |
| --- | --- | --- |
| Naming consistency | Parameter name is derived from context labels; when `delimiter = "/"`, names are path-style and start with `/` | Ensures hierarchical organisation across teams |
| Tagging consistency | All tags sourced from `module.ssm_param_label.tags` (NHS-standard set) | Ensures billing, compliance, and governance controls |
| KMS encryption for secrets | `key_id` is **mandatory** when `type = "SecureString"` | No unencrypted secrets in SSM |
| Secrets never stored by Terraform | `SecureString` values are only sent via write-only `value_wo`; `value_wo` is `ephemeral = true` | No secret values in state or plan files |
| Explicit update trigger | `value_wo_version` is **mandatory** for `SecureString` (no silent default) | A changed value is never silently ignored |
| Creation gating | Resources gated on `module.ssm_param_label.enabled` | Allows disabling entire module via context |

## Usage

### 1. SecureString from an ephemeral source (recommended)

The value is read ephemerally and written write-only, so it never reaches state or plan files.
Use a **non-secret** version number, such as the source parameter's SSM version, as the update trigger.

```hcl
data "aws_ssm_parameter" "source_meta" {
  name            = "/bcss/test/shared/default/exports/NOTIFY_API_KEY"
  with_decryption = false # only the version is needed here
}

ephemeral "aws_ssm_parameter" "source" {
  arn = data.aws_ssm_parameter.source_meta.arn
}

module "notify_api_key" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/ssm-parameter-wo?ref=<tag>"

  context          = module.this.context
  delimiter        = "/"
  label_value_case = "none"
  name             = "NOTIFY_API_KEY"

  type             = "SecureString"
  key_id           = module.kms.key_arn
  value_wo         = ephemeral.aws_ssm_parameter.source.value
  value_wo_version = data.aws_ssm_parameter.source_meta.version
}
```

### 2. Console-managed SecureString (Terraform seeds once, never overwrites)

```hcl
module "console_managed_secret" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/ssm-parameter-wo?ref=<tag>"

  context = module.this.context
  name    = "third-party-api-key"

  type                 = "SecureString"
  key_id               = module.kms.key_arn
  value_wo             = "CHANGE_ME"
  value_wo_version     = 1
  ignore_value_changes = true
}
```

### 3. Plain String parameter

```hcl
module "log_level" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/ssm-parameter-wo?ref=<tag>"

  context = module.this.context
  name    = "log-level"

  type  = "String"
  value = "INFO"
}
```

### 4. StringList parameter

```hcl
module "allowed_ips" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/ssm-parameter-wo?ref=<tag>"

  context = module.this.context
  name    = "allowed-ips"

  type   = "StringList"
  values = ["10.0.0.0/8", "192.168.0.0/16"] # JSON-encoded before storage
}
```

## Migrating from `ssm-parameter`

The module includes `moved` blocks from `module.ssm_parameter.aws_ssm_parameter.{this,ignore_value}`.
Change a caller's `source` from `ssm-parameter` to `ssm-parameter-wo` and keep the module call name.
Existing parameters then move in place on the next plan, with no destroy/create and no `terraform state mv`.

For `SecureString` callers you must also provide `value_wo_version`. `value` still works, but switch to `value_wo` to accept ephemeral values.

## Conventions

- **Type selection:**
  - `String` / `StringList` — non-secret configuration. Stored in state as `insecure_value` and exposed via the `value` output.
  - `SecureString` — secrets. **Requires `key_id` and `value_wo_version`.** The value is never stored in state or plan files, and the `value`, `raw_value` and `secure_value` outputs are always `null`.
- **Choosing `value_wo_version`:** use a number that changes when the secret changes but reveals nothing about it, such as the source SSM parameter's `version` or a manually bumped revision. Do **not** derive it from a hash of the secret.
- **Console or rotation-managed values:** set `ignore_value_changes = true`. Terraform seeds the value on creation and never overwrites it. Toggling this flag transfers management between two Terraform addresses for the same SSM parameter; the old address must be destroyed before the new address writes. If an apply is interrupted during a toggle, run a refreshed plan and verify the parameter will be recreated if the destroy completed before the write.
- **Naming:** Parameter names are derived from context labels. When `delimiter = "/"`, names are path-style with a leading `/`. Override with `parameter_name` if custom naming is required.

## What this module does NOT do

- **Read or decrypt secrets:** callers supply values. Use `ephemeral "aws_ssm_parameter"` or other ephemeral sources to avoid state exposure.
- **Hash values into versions:** `value_wo_version` must be supplied by the caller.
- **Create KMS keys or IAM permissions:** provide an existing key via `key_id`; attach access policies separately.
- **Rotate secrets:** use `ignore_value_changes = true` when rotation automation owns the value.
- **Share parameters across AWS accounts.**

## Validation

All rules are variable validations, so they fail before the provider's own argument checks run:

- `type` must be `String`, `StringList` or `SecureString`
- `SecureString` requires `key_id`, `value_wo_version`, and either `value_wo` (preferred) or `value`
- `value_wo` and `value_wo_version` are only valid for `SecureString`
- `values` is only valid for `StringList`
- `value`, `values` and `value_wo` are mutually exclusive
- `String` / `StringList` require `value` or `values`
- `parameter_name`, when set, must start with `/`

## Testing

```bash
make terraform-test module=ssm-parameter-wo
```

Tests use `mock_provider` and `command = plan`, because `terraform test` cannot re-supply ephemeral inputs to the apply phase.
`make terraform-test module=ssm-parameter-wo` also checks the generated dependency graph to guard the resource handoff order when `ignore_value_changes` is toggled.

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.66.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_ssm_param_label"></a> [ssm\_param\_label](#module\_ssm\_param\_label) | ../tags | n/a |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_ssm_parameter.ignore_value](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |

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
| <a name="input_ignore_value_changes"></a> [ignore\_value\_changes](#input\_ignore\_value\_changes) | Whether to create the SSM parameter and then ignore changes to its value, e.g. when the value is managed in the console or by rotation automation | `bool` | `false` | no |
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
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to the caller module path when not set. | `string` | `null` | no |
| <a name="input_tier"></a> [tier](#input\_tier) | Parameter tier to assign to the parameter. If not specified, will use the default parameter tier for the region. Valid tiers are Standard, Advanced, and Intelligent-Tiering. Downgrading an Advanced tier parameter to Standard will recreate the resource | `string` | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_type"></a> [type](#input\_type) | Type of the parameter. Valid types are `String`, `StringList` and `SecureString` | `string` | n/a | yes |
| <a name="input_value"></a> [value](#input\_value) | Value of the parameter. For `String`/`StringList` it is stored in state as `insecure_value`. For `SecureString` it is sent via the write-only `value_wo` argument and never stored; prefer `value_wo` so ephemeral values can be used. | `string` | `null` | no |
| <a name="input_value_wo"></a> [value\_wo](#input\_value\_wo) | Write-only value for a `SecureString` parameter. Accepts ephemeral values and is never stored in state or plan files. Requires `value_wo_version`. | `string` | `null` | no |
| <a name="input_value_wo_version"></a> [value\_wo\_version](#input\_value\_wo\_version) | Version trigger for the write-only SecureString value. Required for `SecureString`; Terraform only re-sends the value when this number changes. | `number` | `null` | no |
| <a name="input_values"></a> [values](#input\_values) | List of values for a `StringList` parameter (JSON-encoded before being stored). | `list(string)` | `[]` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_insecure_value"></a> [insecure\_value](#output\_insecure\_value) | Value of a `String`/`StringList` parameter. Always null for `SecureString`. |
| <a name="output_raw_value"></a> [raw\_value](#output\_raw\_value) | Raw stored value of a `String`/`StringList` parameter. Always null for `SecureString`. Use `value` for the JSON-decoded value. |
| <a name="output_secure_type"></a> [secure\_type](#output\_secure\_type) | Whether the SSM parameter is a SecureString |
| <a name="output_secure_value"></a> [secure\_value](#output\_secure\_value) | Always null: SecureString values are write-only and never read back into state. |
| <a name="output_ssm_parameter_arn"></a> [ssm\_parameter\_arn](#output\_ssm\_parameter\_arn) | The ARN of the parameter |
| <a name="output_ssm_parameter_name"></a> [ssm\_parameter\_name](#output\_ssm\_parameter\_name) | Name of the parameter |
| <a name="output_ssm_parameter_type"></a> [ssm\_parameter\_type](#output\_ssm\_parameter\_type) | Type of the parameter |
| <a name="output_ssm_parameter_version"></a> [ssm\_parameter\_version](#output\_ssm\_parameter\_version) | Version of the parameter |
| <a name="output_value"></a> [value](#output\_value) | Value of a `String`/`StringList` parameter after jsondecode() where possible. Always null for `SecureString`. |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
