# AWS SES Terraform module

Thin NHS wrapper around [cloudposse/ses/aws](https://registry.terraform.io/modules/cloudposse/ses/aws) that enforces the screening platform's baseline controls.

## Fixed controls

| Setting | Value | Reason |
| --- | --- | --- |
| `iam_create_access_key` | `false` | IAM access keys must never be stored in Terraform state |
| `iam_create_ses_smtp_password` | `false` | SMTP passwords must never be stored in Terraform state |
| `ses_user_enabled` | `false` | ECS tasks authenticate via IAM roles, not IAM users |
| `ses_group_enabled` | `false` | ECS tasks authenticate via IAM roles, not IAM groups |
| `custom_from_behavior_on_mx_failure` | `UseDefaultValue` | Sensible default; falls back to amazonses.com on MX failure |

## Provider requirements

The upstream `cloudposse/ses/aws` module requires the `cloudposse/awsutils` provider. Add it to the consuming stack's `versions.tf` and `providers.tf`:

```hcl
# versions.tf
terraform {
  required_providers {
    awsutils = {
      source  = "cloudposse/awsutils"
      version = ">= 0.11.0"
    }
  }
}

# providers.tf
provider "awsutils" {
  region = var.aws_region
}
```

## Usage

### Domain identity with Route53 verification

```hcl
module "ses" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/ses?ref=<tag>"

  context = module.this.context
  name    = "ses"

  domain  = "example.nhs.uk"
  zone_id = module.r53.zone_id

  verify_domain = true
  verify_dkim   = true

  custom_from_subdomain          = ["mail"]
  custom_from_dns_record_enabled = true
}
```

### Domain identity without Route53 (DNS managed externally)

```hcl
module "ses" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/ses?ref=<tag>"

  context = module.this.context
  name    = "ses"

  domain = "example.nhs.uk"
  # zone_id omitted — use the ses_domain_identity_verification_token and
  # ses_dkim_tokens outputs to add the required DNS records manually
}
```

### Domain identity with custom MAIL FROM

```hcl
module "ses" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/ses?ref=<tag>"

  context = module.this.context
  name    = "ses"

  domain  = "${var.environment}.bcss.nhs.uk"
  zone_id = module.r53.hosted_zone_ids["public"]

  verify_domain     = true
  verify_dkim       = true
  create_spf_record = true

  custom_from_subdomain          = ["mail"]
  custom_from_dns_record_enabled = true
}
```

## Conventions

* The SES domain identity name is the `domain` value itself; it is not derived from context labels.
* `verify_domain`, `verify_dkim`, `create_spf_record`, and `custom_from_dns_record_enabled` all require `zone_id` to be set — the module will fail at plan time if they are enabled without one.
* IAM access keys and SMTP passwords are hardcoded to never be stored in Terraform state.
* IAM user and group creation are hardcoded off. Grant SES sending permissions to ECS task IAM roles directly via `ses:SendRawEmail` on the domain identity ARN.
* Every AWS account starts in SES Sandbox mode. Sending to unverified addresses requires a production access request via AWS Support.

## What this module does NOT do

* Move the account out of SES Sandbox mode — raise an AWS Support request to enable production sending.
* Create or manage Route53 hosted zones — provide an existing zone ID via `zone_id`.
* Create IAM users or groups — grant `ses:SendRawEmail` on the domain identity ARN directly to ECS task roles.
* Configure SES sending quotas, suppression lists, or configuration sets — manage those resources separately.
* Create an SES email identity for individual addresses — this module handles domain identities only.

## Validation

The following constraints are enforced at `plan` time via preconditions in `validations.tf`:

* **Route53 dependency**: `verify_domain`, `verify_dkim`, `create_spf_record`, and `custom_from_dns_record_enabled` (when `custom_from_subdomain` is non-empty) all require `zone_id` to be set.

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.28 |
| <a name="requirement_awsutils"></a> [awsutils](#requirement\_awsutils) | >= 0.11.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_ses"></a> [ses](#module\_ses) | cloudposse/ses/aws | 0.25.2 |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [terraform_data.validations](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_application_role"></a> [application\_role](#input\_application\_role) | The role the application is performing | `string` | `"General"` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "project": null,<br/>  "regex_replace_chars": null,<br/>  "region": null,<br/>  "service": null,<br/>  "stack": null,<br/>  "tags": {},<br/>  "terraform_source": null,<br/>  "workspace": null<br/>}</pre> | no |
| <a name="input_create_spf_record"></a> [create\_spf\_record](#input\_create\_spf\_record) | When true, creates an SPF TXT record in Route53 for the domain. Requires zone\_id to be set. | `bool` | `false` | no |
| <a name="input_custom_from_behavior_on_mx_failure"></a> [custom\_from\_behavior\_on\_mx\_failure](#input\_custom\_from\_behavior\_on\_mx\_failure) | The behaviour when the MX record for the custom MAIL FROM domain cannot be found. Valid values: UseDefaultValue (fall back to amazonses.com), RejectMessage (reject the outbound email). | `string` | `"UseDefaultValue"` | no |
| <a name="input_custom_from_dns_record_enabled"></a> [custom\_from\_dns\_record\_enabled](#input\_custom\_from\_dns\_record\_enabled) | When true, creates a Route53 MX record for the custom MAIL FROM subdomain. Only takes effect when custom\_from\_subdomain is non-empty. Requires zone\_id to be set. | `bool` | `false` | no |
| <a name="input_custom_from_subdomain"></a> [custom\_from\_subdomain](#input\_custom\_from\_subdomain) | List of subdomains to use as the MAIL FROM (return-path) address. For example, ["mail"] sets the MAIL FROM domain to mail.<domain>. Required for DMARC alignment when verify\_dkim is true. | `list(string)` | `[]` | no |
| <a name="input_data_classification"></a> [data\_classification](#input\_data\_classification) | Used to identify the data classification of the resource, e.g 1-5 | `string` | `"n/a"` | no |
| <a name="input_data_type"></a> [data\_type](#input\_data\_type) | The tag data\_type | `string` | `"None"` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>    format = string<br/>    labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | The domain to create the SES identity for, e.g. "example.nhs.uk". | `string` | n/a | yes |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_iam_allowed_resources"></a> [iam\_allowed\_resources](#input\_iam\_allowed\_resources) | List of resource ARNs that the IAM permissions apply to. Wildcards are accepted. When empty, the policy applies to all resources (`"*"`). | `list(string)` | `[]` | no |
| <a name="input_iam_permissions"></a> [iam\_permissions](#input\_iam\_permissions) | List of IAM action strings granted to the SES IAM user or group. | `list(string)` | <pre>[<br/>  "ses:SendRawEmail"<br/>]</pre> | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_on_off_pattern"></a> [on\_off\_pattern](#input\_on\_off\_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_ses_group_enabled"></a> [ses\_group\_enabled](#input\_ses\_group\_enabled) | When true, creates an IAM group with permission to send emails via SES. The group name is derived from context labels via module.this.id. | `bool` | `false` | no |
| <a name="input_ses_group_path"></a> [ses\_group\_path](#input\_ses\_group\_path) | The IAM path for the SES IAM group. | `string` | `"/"` | no |
| <a name="input_ses_user_enabled"></a> [ses\_user\_enabled](#input\_ses\_user\_enabled) | When true, creates an IAM user with permission to send emails via SES. Access key and SMTP password are never stored in Terraform state — distribute credentials out-of-band. | `bool` | `false` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to the caller module path when not set. | `string` | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_verify_dkim"></a> [verify\_dkim](#input\_verify\_dkim) | When true, creates Route53 CNAME records for DKIM signing verification. Requires zone\_id to be set. | `bool` | `false` | no |
| <a name="input_verify_domain"></a> [verify\_domain](#input\_verify\_domain) | When true, creates a Route53 TXT record for SES domain ownership verification. Requires zone\_id to be set. | `bool` | `false` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Route53 parent zone ID. When provided, the module creates Route53 DNS records for domain verification, DKIM, SPF, and the custom MAIL FROM MX record. Leave empty to manage DNS records outside Terraform. | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_custom_from_domain"></a> [custom\_from\_domain](#output\_custom\_from\_domain) | The custom MAIL FROM domain (e.g. mail.example.nhs.uk). Empty when custom\_from\_subdomain is not set. |
| <a name="output_ses_dkim_tokens"></a> [ses\_dkim\_tokens](#output\_ses\_dkim\_tokens) | List of DKIM tokens to add as CNAME records in your DNS zone to enable DKIM signing. Only required when zone\_id is not provided and verify\_dkim is managed externally. |
| <a name="output_ses_domain_identity_arn"></a> [ses\_domain\_identity\_arn](#output\_ses\_domain\_identity\_arn) | The ARN of the SES domain identity. |
| <a name="output_ses_domain_identity_verification_token"></a> [ses\_domain\_identity\_verification\_token](#output\_ses\_domain\_identity\_verification\_token) | The TXT record value to add to your DNS zone to verify SES domain ownership. Only required when zone\_id is not provided and verify\_domain is managed externally. |
| <a name="output_ses_group_name"></a> [ses\_group\_name](#output\_ses\_group\_name) | The name of the IAM group created for SES sending. Empty when ses\_group\_enabled is false. |
| <a name="output_spf_record"></a> [spf\_record](#output\_spf\_record) | The SPF TXT record value. Add this to your DNS zone when create\_spf\_record is false and you manage DNS records externally. |
| <a name="output_user_arn"></a> [user\_arn](#output\_user\_arn) | The ARN of the IAM user created for SES sending. Empty when ses\_user\_enabled is false. |
| <a name="output_user_name"></a> [user\_name](#output\_user\_name) | The name of the IAM user created for SES sending. Empty when ses\_user\_enabled is false. |
<!-- END_TF_DOCS -->
