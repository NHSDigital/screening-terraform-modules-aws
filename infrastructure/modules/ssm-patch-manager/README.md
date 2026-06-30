# SSM Patch Manager

NHS Screening wrapper around the community
[`cloudposse/ssm-patch-manager/aws`](https://registry.terraform.io/modules/cloudposse/ssm-patch-manager/aws/latest)
module that consumes shared `context.tf` naming and tagging and scopes the
interface to what the BCSS shared stack requires.

## What this module enforces

| Control | How it is enforced |
| --- | --- |
| Shared naming and tagging | Uses `context.tf` via `module.this` and forwards context to the upstream module |
| Creation gate | Resources gated via `module.this.enabled` through the upstream CloudPosse context |
| Patch compliance level | Defaults to `HIGH`; consumer may tighten but not loosen without explicit override |
| S3 log output | Enabled by default for audit and compliance |

## Usage

### Minimal — module creates its own log bucket

```hcl
module "ssm_patch_manager" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/ssm-patch-manager?ref=<tag>"

  service     = "bcss"
  project     = "shared"
  environment = "prod"
  name        = "patch-manager"

  install_maintenance_window_schedule = "cron(0 0 21 ? * WED *)"
  install_maintenance_windows_targets = [
    { key = "tag:PatchGroup", values = ["TOPATCH"] }
  ]
  install_patch_groups = ["TOPATCH"]

  scan_maintenance_window_schedule = "cron(0 0 18 ? * WED *)"
  scan_maintenance_windows_targets = [
    { key = "tag:PatchGroup", values = ["TOSCAN"] }
  ]
  scan_patch_groups = ["TOSCAN"]
}
```

### With an existing S3 bucket for logs

```hcl
module "ssm_patch_manager" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/ssm-patch-manager?ref=<tag>"

  service     = "bcss"
  project     = "shared"
  environment = "prod"
  name        = "patch-manager"

  install_maintenance_window_schedule = "cron(0 0 21 ? * WED *)"
  install_maintenance_windows_targets = [
    { key = "tag:PatchGroup", values = ["TOPATCH"] }
  ]
  install_patch_groups = ["TOPATCH"]

  scan_maintenance_window_schedule = "cron(0 0 18 ? * WED *)"
  scan_maintenance_windows_targets = [
    { key = "tag:PatchGroup", values = ["TOSCAN"] }
  ]
  scan_patch_groups = ["TOSCAN"]

  bucket_id = [module.ssm_logs_bucket.bucket_id]
}
```

## Conventions

- Maintenance window targets use EC2 tag key/value pairs (e.g. `tag:PatchGroup`). EC2 instances must have the corresponding tag applied for SSM to discover them.
- `install_patch_groups` and `scan_patch_groups` must match the `PatchGroup` tag values on the target instances.
- When `bucket_id` is empty (the default), the upstream module creates a dedicated S3 bucket for patch logs. Pass an existing bucket ID to reuse a shared log bucket.
- Scan and install window schedules must not overlap — ensure the scan window completes before the install window starts.

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
| <a name="module_ssm_patch_manager"></a> [ssm\_patch\_manager](#module\_ssm\_patch\_manager) | cloudposse/ssm-patch-manager/aws | 1.0.3 |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_application_role"></a> [application\_role](#input\_application\_role) | The role the application is performing | `string` | `"General"` | no |
| <a name="input_approved_patches_compliance_level"></a> [approved\_patches\_compliance\_level](#input\_approved\_patches\_compliance\_level) | Severity of the compliance violation when an approved patch is missing. Valid values: CRITICAL, HIGH, MEDIUM, LOW, INFORMATIONAL, UNSPECIFIED. | `string` | `"HIGH"` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_bucket_id"></a> [bucket\_id](#input\_bucket\_id) | ID of an existing S3 bucket to use for patch logs. Leave empty to have the module create a dedicated bucket. | `list(string)` | `[]` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "project": null,<br/>  "regex_replace_chars": null,<br/>  "region": null,<br/>  "service": null,<br/>  "stack": null,<br/>  "tags": {},<br/>  "terraform_source": null,<br/>  "workspace": null<br/>}</pre> | no |
| <a name="input_data_classification"></a> [data\_classification](#input\_data\_classification) | Used to identify the data classification of the resource, e.g 1-5 | `string` | `"n/a"` | no |
| <a name="input_data_type"></a> [data\_type](#input\_data\_type) | The tag data\_type | `string` | `"None"` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>    format = string<br/>    labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_install_maintenance_window_cutoff"></a> [install\_maintenance\_window\_cutoff](#input\_install\_maintenance\_window\_cutoff) | Number of hours before the install window ends at which SSM stops scheduling new tasks. | `number` | `1` | no |
| <a name="input_install_maintenance_window_duration"></a> [install\_maintenance\_window\_duration](#input\_install\_maintenance\_window\_duration) | Duration of the install maintenance window in hours. | `number` | `3` | no |
| <a name="input_install_maintenance_window_schedule"></a> [install\_maintenance\_window\_schedule](#input\_install\_maintenance\_window\_schedule) | Cron or rate expression for the patch install maintenance window, e.g. cron(0 0 21 ? * WED *). | `string` | `null` | no |
| <a name="input_install_maintenance_windows_targets"></a> [install\_maintenance\_windows\_targets](#input\_install\_maintenance\_windows\_targets) | List of target definitions (key/values tag pairs) identifying which EC2 instances the install window applies to. | <pre>list(object({<br/>    key    = string<br/>    values = list(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_install_patch_groups"></a> [install\_patch\_groups](#input\_install\_patch\_groups) | List of patch group names to register with the install maintenance window. | `list(string)` | `[]` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_max_concurrency"></a> [max\_concurrency](#input\_max\_concurrency) | Maximum number of targets the task runs against in parallel. | `number` | `20` | no |
| <a name="input_max_errors"></a> [max\_errors](#input\_max\_errors) | Maximum number of errors allowed before the task stops being scheduled. | `number` | `50` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_on_off_pattern"></a> [on\_off\_pattern](#input\_on\_off\_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_operating_system"></a> [operating\_system](#input\_operating\_system) | Operating system the patch baseline applies to. Must match the OS of the EC2 instances being targeted. | `string` | `"AMAZON_LINUX_2"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_patch_baseline_approval_rules"></a> [patch\_baseline\_approval\_rules](#input\_patch\_baseline\_approval\_rules) | Approval rules for the patch baseline. Each rule controls which patches are automatically approved. approve\_after\_days and approve\_until\_date are mutually exclusive within a rule. | <pre>list(object({<br/>    approve_after_days  = optional(number)<br/>    approve_until_date  = optional(string)<br/>    compliance_level    = string<br/>    enable_non_security = bool<br/>    patch_baseline_filters = list(object({<br/>      name   = string<br/>      values = list(string)<br/>    }))<br/>  }))</pre> | <pre>[<br/>  {<br/>    "approve_after_days": 7,<br/>    "compliance_level": "HIGH",<br/>    "enable_non_security": true,<br/>    "patch_baseline_filters": [<br/>      {<br/>        "name": "PRODUCT",<br/>        "values": [<br/>          "AmazonLinux2",<br/>          "AmazonLinux2.0"<br/>        ]<br/>      },<br/>      {<br/>        "name": "CLASSIFICATION",<br/>        "values": [<br/>          "Security",<br/>          "Bugfix"<br/>        ]<br/>      },<br/>      {<br/>        "name": "SEVERITY",<br/>        "values": [<br/>          "Critical",<br/>          "Important"<br/>        ]<br/>      }<br/>    ]<br/>  }<br/>]</pre> | no |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_reboot_option"></a> [reboot\_option](#input\_reboot\_option) | Reboot behaviour after patch installation. RebootIfNeeded reboots only if new patches were installed or patches are pending reboot. NoReboot skips reboot entirely. | `string` | `"RebootIfNeeded"` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_s3_bucket_prefix_install_logs"></a> [s3\_bucket\_prefix\_install\_logs](#input\_s3\_bucket\_prefix\_install\_logs) | S3 key prefix for install task logs. | `string` | `"install"` | no |
| <a name="input_s3_bucket_prefix_scan_logs"></a> [s3\_bucket\_prefix\_scan\_logs](#input\_s3\_bucket\_prefix\_scan\_logs) | S3 key prefix for scan task logs. | `string` | `"scanning"` | no |
| <a name="input_s3_log_output_enabled"></a> [s3\_log\_output\_enabled](#input\_s3\_log\_output\_enabled) | Write patch task output to an S3 bucket. Recommended for audit and compliance. | `bool` | `true` | no |
| <a name="input_scan_maintenance_window_cutoff"></a> [scan\_maintenance\_window\_cutoff](#input\_scan\_maintenance\_window\_cutoff) | Number of hours before the scan window ends at which SSM stops scheduling new tasks. | `number` | `1` | no |
| <a name="input_scan_maintenance_window_duration"></a> [scan\_maintenance\_window\_duration](#input\_scan\_maintenance\_window\_duration) | Duration of the scan maintenance window in hours. | `number` | `3` | no |
| <a name="input_scan_maintenance_window_schedule"></a> [scan\_maintenance\_window\_schedule](#input\_scan\_maintenance\_window\_schedule) | Cron or rate expression for the patch scan maintenance window, e.g. cron(0 0 18 ? * WED *). | `string` | `null` | no |
| <a name="input_scan_maintenance_windows_targets"></a> [scan\_maintenance\_windows\_targets](#input\_scan\_maintenance\_windows\_targets) | List of target definitions (key/values tag pairs) identifying which EC2 instances the scan window applies to. | <pre>list(object({<br/>    key    = string<br/>    values = list(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_scan_patch_groups"></a> [scan\_patch\_groups](#input\_scan\_patch\_groups) | List of patch group names to register with the scan maintenance window. | `list(string)` | `[]` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_service_role_arn"></a> [service\_role\_arn](#input\_service\_role\_arn) | ARN of the IAM role SSM assumes when running maintenance window tasks. If null, SSM uses the account service-linked role. | `string` | `null` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to the caller module path when not set. | `string` | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_install_maintenance_window_id"></a> [install\_maintenance\_window\_id](#output\_install\_maintenance\_window\_id) | ID of the SSM install maintenance window. |
| <a name="output_install_maintenance_window_target_id"></a> [install\_maintenance\_window\_target\_id](#output\_install\_maintenance\_window\_target\_id) | ID of the install maintenance window target. |
| <a name="output_install_maintenance_window_task_id"></a> [install\_maintenance\_window\_task\_id](#output\_install\_maintenance\_window\_task\_id) | ID of the install maintenance window task. |
| <a name="output_install_patch_group_id"></a> [install\_patch\_group\_id](#output\_install\_patch\_group\_id) | ID of the install patch group. |
| <a name="output_patch_baseline_arn"></a> [patch\_baseline\_arn](#output\_patch\_baseline\_arn) | ARN of the SSM patch baseline. |
| <a name="output_scan_maintenance_window_target_id"></a> [scan\_maintenance\_window\_target\_id](#output\_scan\_maintenance\_window\_target\_id) | ID of the scan maintenance window target. |
| <a name="output_scan_maintenance_window_task_id"></a> [scan\_maintenance\_window\_task\_id](#output\_scan\_maintenance\_window\_task\_id) | ID of the scan maintenance window task. |
| <a name="output_scan_patch_group_id"></a> [scan\_patch\_group\_id](#output\_scan\_patch\_group\_id) | ID of the scan patch group. |
| <a name="output_ssm_patch_log_s3_bucket_arn"></a> [ssm\_patch\_log\_s3\_bucket\_arn](#output\_ssm\_patch\_log\_s3\_bucket\_arn) | ARN of the S3 bucket used for patch logs. Empty when bucket\_id is supplied. |
| <a name="output_ssm_patch_log_s3_bucket_id"></a> [ssm\_patch\_log\_s3\_bucket\_id](#output\_ssm\_patch\_log\_s3\_bucket\_id) | ID of the S3 bucket used for patch logs. Empty when bucket\_id is supplied. |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
