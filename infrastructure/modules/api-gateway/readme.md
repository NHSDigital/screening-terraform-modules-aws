# API Gateway

Minimal NHS Screening wrapper for an API Gateway v2 HTTP API fronting a Lambda
webhook endpoint. This module is intended for small webhook publisher use cases
such as the future shared GitHub runner or ARC stack, and consumes the shared
`context.tf` for naming and tagging.

## What this module enforces

|Control|How it is enforced|
|---|---|
|Protocol|Creates an API Gateway v2 HTTP API only; no REST API resources are used|
|Integration|Creates a Lambda proxy integration with payload format version `2.0`|
|Stage deployment|Creates a single stage with `auto_deploy = true`|
|Default route protection|Applies explicit non-zero default route throttling so the stage does not accidentally return `429` for every request|
|Logging|Enables API access logging to CloudWatch Logs|
|Invoke permissions|Creates Lambda permission scoped to the API execution ARN|
|Tagging|Tags supported resources via `module.this.tags`|
|Creation gate|Resource creation is gated by `module.this.enabled`|

## Usage

### Minimal webhook endpoint

```hcl
module "github_arc_webhook_api" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/api-gateway?ref=<tag>"

  enabled        = local.deploy_github_arc
  name           = "github-arc-webhook"
  workspace      = terraform.workspace
  tags           = module.tags.tags
  labels_as_tags = []

  lambda_invoke_arn           = module.webhook_publisher.lambda_function_invoke_arn
  lambda_function_name_or_arn = module.webhook_publisher.lambda_function_name
}
```

### Explicit route and stage

```hcl
module "webhook_api" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/api-gateway?ref=<tag>"

  enabled        = true
  name           = "webhook"
  workspace      = terraform.workspace
  tags           = module.tags.tags
  labels_as_tags = []

  route_key  = "POST /arc/webhook"
  stage_name = "live"

  lambda_invoke_arn           = aws_lambda_function.publisher.invoke_arn
  lambda_function_name_or_arn = aws_lambda_function.publisher.function_name
}
```

### Custom API name with longer log retention

```hcl
module "runner_webhook_api" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/api-gateway?ref=<tag>"

  enabled        = true
  name           = "github-runner-webhook"
  workspace      = terraform.workspace
  tags           = module.tags.tags
  labels_as_tags = []

  custom_name                  = "github-runner-webhook-${terraform.workspace}"
  description                  = "Webhook endpoint for GitHub ARC event publishing."
  access_log_retention_in_days = 90
  default_route_throttling_burst_limit = 200
  default_route_throttling_rate_limit  = 100

  lambda_invoke_arn           = module.publisher.lambda_function_invoke_arn
  lambda_function_name_or_arn = module.publisher.lambda_function_arn
}
```

## Conventions

* `custom_name` is optional. When omitted, the API name is derived from
  `module.this.id` so it follows the same naming and tagging pattern as other
  wrappers in this repository.
* `stage_name` defaults to `$default` to keep the caller experience simple and
  avoid separate deployment resources.
* `route_key` defaults to `POST /webhook`, which matches the primary ARC webhook
  endpoint use case.
* Default route throttling is set explicitly with non-zero defaults so the
  generated stage can accept webhook traffic without additional manual patching.
* The module expects the Lambda invoke ARN for the integration and a Lambda
  function name or ARN for the invoke permission.

## What this module does NOT do

* Create REST API v1 resources.
* Create API keys, usage plans, or Secrets Manager tokens.
* Create custom domains, ACM certificates, or Route 53 records.
* Manage multiple routes, authorisers, CORS policies, or VPC links.

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.42 |

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
| [aws_apigatewayv2_api.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api) | resource |
| [aws_apigatewayv2_integration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_route.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_stage.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_stage) | resource |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_lambda_permission.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_access_log_retention_in_days"></a> [access\_log\_retention\_in\_days](#input\_access\_log\_retention\_in\_days) | CloudWatch Logs retention for API access logs. | `number` | `30` | no |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_application_role"></a> [application\_role](#input\_application\_role) | The role the application is performing | `string` | `"General"` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "project": null,<br/>  "regex_replace_chars": null,<br/>  "region": null,<br/>  "service": null,<br/>  "stack": null,<br/>  "tags": {},<br/>  "terraform_source": null,<br/>  "workspace": null<br/>}</pre> | no |
| <a name="input_custom_name"></a> [custom\_name](#input\_custom\_name) | Optional explicit API name. When null, the name is derived from module.this.id. | `string` | `null` | no |
| <a name="input_data_classification"></a> [data\_classification](#input\_data\_classification) | Used to identify the data classification of the resource, e.g 1-5 | `string` | `"n/a"` | no |
| <a name="input_data_type"></a> [data\_type](#input\_data\_type) | The tag data\_type | `string` | `"None"` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Description for the HTTP API. Keep this focused on the webhook endpoint purpose. | `string` | `"HTTP API for a Lambda-backed webhook endpoint."` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>    format = string<br/>    labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_enable_detailed_metrics"></a> [enable\_detailed\_metrics](#input\_enable\_detailed\_metrics) | Whether to enable detailed CloudWatch metrics on the default route settings. | `bool` | `false` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_integration_timeout_milliseconds"></a> [integration\_timeout\_milliseconds](#input\_integration\_timeout\_milliseconds) | Timeout for the Lambda proxy integration in milliseconds. HTTP APIs support 50-30000 ms. | `number` | `30000` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_lambda_function_name_or_arn"></a> [lambda\_function\_name\_or\_arn](#input\_lambda\_function\_name\_or\_arn) | Lambda function name or ARN used when granting API Gateway permission to invoke the function. | `string` | n/a | yes |
| <a name="input_lambda_invoke_arn"></a> [lambda\_invoke\_arn](#input\_lambda\_invoke\_arn) | Invoke ARN of the Lambda function that will receive the webhook requests. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_on_off_pattern"></a> [on\_off\_pattern](#input\_on\_off\_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_route_key"></a> [route\_key](#input\_route\_key) | Route key for the webhook endpoint. Use either '$default' or 'METHOD /path', for example 'POST /webhook'. | `string` | `"POST /webhook"` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | Stage name for the HTTP API. Defaults to '$default' so callers get auto-deployed changes without managing deployments. | `string` | `"$default"` | no |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to the caller module path when not set. | `string` | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_api_endpoint"></a> [api\_endpoint](#output\_api\_endpoint) | The base invoke URL of the HTTP API. |
| <a name="output_api_id"></a> [api\_id](#output\_api\_id) | The ID of the HTTP API. |
| <a name="output_execution_arn"></a> [execution\_arn](#output\_execution\_arn) | The execution ARN of the HTTP API, suitable for IAM policies or permissions. |
| <a name="output_integration_id"></a> [integration\_id](#output\_integration\_id) | The ID of the Lambda proxy integration. |
| <a name="output_route_id"></a> [route\_id](#output\_route\_id) | The ID of the webhook route. |
| <a name="output_stage_name"></a> [stage\_name](#output\_stage\_name) | The deployed stage name. |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
