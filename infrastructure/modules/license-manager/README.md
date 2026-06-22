# License Manager

NHS Screening module for AWS License Manager license configurations. Creates self-managed license configurations (vCPU / Core / Socket / Instance counted) with optional hard limits and resource associations. Uses the shared `context.tf` for naming and tagging.

## What this module enforces

| Control | How it is enforced |
| --- | --- |
| License counting validation | Only valid counting types (`vCPU`, `Instance`, `Core`, `Socket`) are accepted |
| Tagging and naming | Uses shared `context.tf` (`module.this`) for tags and naming |
| Resource enable/disable | Creation gated by `module.this.enabled` |
| Stable associations | Map-based `for_each` prevents unnecessary re-creation of resource associations |

## Usage

### Minimal license configuration (vCPU counted)

```hcl
module "license_manager" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/license-manager?ref=<tag>"

  service     = "bcss"
  project     = "platform"
  environment = "prod"
  name        = "windows-server"

  description           = "Windows Server BYOL licenses"
  license_counting_type = "vCPU"
  license_count         = 100
}
```

### License configuration with hard limit and rules

```hcl
module "license_sql" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/license-manager?ref=<tag>"

  service     = "bcss"
  project     = "database"
  environment = "prod"
  name        = "sql-server-enterprise"

  description              = "SQL Server Enterprise BYOL licenses"
  license_counting_type    = "Core"
  license_count            = 64
  license_count_hard_limit = true

  license_rules = [
    "#minimumCores=4",
    "#allowedTenancy=EC2-DedicatedHost"
  ]
}
```

### License configuration with AMI associations

```hcl
module "license_windows_with_amis" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/license-manager?ref=<tag>"

  service     = "bcss"
  project     = "compute"
  environment = "prod"
  name        = "windows-2022-byol"

  description           = "Windows Server 2022 BYOL licenses"
  license_counting_type = "Instance"
  license_count         = 50

  associated_resource_arns = {
    windows-2022-base    = "arn:aws:ec2:eu-west-2::image/ami-0123456789abcdef0"
    windows-2022-iis     = "arn:aws:ec2:eu-west-2::image/ami-0fedcba9876543210"
    windows-2022-sql-web = "arn:aws:ec2:eu-west-2::image/ami-01234567890fedcba"
  }
}
```

## Conventions

- `license_counting_type` is required and must be one of `vCPU`, `Instance`, `Core`, or `Socket`.
- `license_count` is optional; when null, no count limit is tracked.
- `license_count_hard_limit` defaults to `false`; set to `true` to block further usage once the count is exceeded.
- `license_rules` is an optional list of rules in the format `#RuleType=RuleValue`; supported rule types include `minimumVcpus`, `maximumVcpus`, `minimumCores`, `maximumCores`, `minimumSockets`, `maximumSockets`, and `allowedTenancy`.
- `associated_resource_arns` is a map where keys are stable identifiers (e.g., `windows-ami-2022`) and values are ARNs of AMIs, EC2 instances, hosts, or other supported resources. Map-based approach prevents unnecessary re-creation when associations change.
- `name_override` can be used to provide a custom name; when null, the name is derived from `module.this.id`.
- **Important:** Removing `license_count` after it has been set is not supported by the License Manager API and requires resource replacement.

## What this module does NOT do

- Create AMIs, EC2 instances, or dedicated hosts; you must provide existing resource ARNs for association.
- Support product licenses from AWS Marketplace (use the License Manager console or native resources for those).
- Manage license grants across AWS Organisations or delegated administrator accounts (this module is for standalone account configurations only).
- Enforce license usage automatically on EC2 instance launch; License Manager tracking is passive unless you configure enforcement rules separately.
- Support license configurations for third-party License Manager integrations (e.g., bring-your-own-license agreements outside AWS).

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.14 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.50.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_licensemanager_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/licensemanager_association) | resource |
| [aws_licensemanager_license_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/licensemanager_license_configuration) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_application_role"></a> [application\_role](#input\_application\_role) | The role the application is performing | `string` | `"General"` | no |
| <a name="input_associated_resource_arns"></a> [associated\_resource\_arns](#input\_associated\_resource\_arns) | Map of resource ARNs to associate with the license configuration.<br/>Keys are stable, caller-supplied identifiers (e.g. `windows-ami-2022`)<br/>used so resources can be added/removed without forcing other<br/>associations to be re-created. Values are the ARNs of AMIs, EC2<br/>instances, hosts, or other supported resources. | `map(string)` | `{}` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "project": null,<br/>  "regex_replace_chars": null,<br/>  "region": null,<br/>  "service": null,<br/>  "stack": null,<br/>  "tags": {},<br/>  "terraform_source": null,<br/>  "workspace": null<br/>}</pre> | no |
| <a name="input_data_classification"></a> [data\_classification](#input\_data\_classification) | Used to identify the data classification of the resource, e.g 1-5 | `string` | `"n/a"` | no |
| <a name="input_data_type"></a> [data\_type](#input\_data\_type) | The tag data\_type | `string` | `"None"` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the License Manager license configuration. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>    format = string<br/>    labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_license_count"></a> [license\_count](#input\_license\_count) | Number of licenses managed by the configuration. Null means no count is tracked. Note: removing this attribute after creation is not supported by the License Manager API and requires resource replacement. | `number` | `null` | no |
| <a name="input_license_count_hard_limit"></a> [license\_count\_hard\_limit](#input\_license\_count\_hard\_limit) | If true, the `license_count` is enforced as a hard limit (further usage is blocked once exceeded). | `bool` | `false` | no |
| <a name="input_license_counting_type"></a> [license\_counting\_type](#input\_license\_counting\_type) | Dimension used to track license inventory. One of: vCPU, Instance, Core, Socket. | `string` | n/a | yes |
| <a name="input_license_rules"></a> [license\_rules](#input\_license\_rules) | Optional list of License Manager rules in the form `#RuleType=RuleValue`.<br/>Supported rule types: minimumVcpus, maximumVcpus, minimumCores, maximumCores,<br/>minimumSockets, maximumSockets, allowedTenancy. Example:<br/>  ["#minimumSockets=2", "#allowedTenancy=EC2-DedicatedHost"] | `list(string)` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_name_override"></a> [name\_override](#input\_name\_override) | Optional explicit name for the License Manager license configuration. When null, the name is derived from the shared context (`module.this.id`). | `string` | `null` | no |
| <a name="input_on_off_pattern"></a> [on\_off\_pattern](#input\_on\_off\_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to the caller module path when not set. | `string` | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_association_ids"></a> [association\_ids](#output\_association\_ids) | Map of license configuration associations keyed by the caller-supplied identifier, with the association ID as the value. |
| <a name="output_license_configuration_arn"></a> [license\_configuration\_arn](#output\_license\_configuration\_arn) | ARN of the License Manager license configuration. |
| <a name="output_license_configuration_id"></a> [license\_configuration\_id](#output\_license\_configuration\_id) | ID (ARN) of the License Manager license configuration. |
| <a name="output_owner_account_id"></a> [owner\_account\_id](#output\_owner\_account\_id) | AWS account ID that owns the license configuration. |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
