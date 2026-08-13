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

	lambda_invoke_arn          = module.webhook_publisher.lambda_function_invoke_arn
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
| terraform | >= 1.13 |
| aws | >= 6.42 |

## Outputs

| Name | Description |
| ---- | ----------- |
| api_id | The ID of the HTTP API. |
| api_endpoint | The base invoke URL of the HTTP API. |
| execution_arn | The execution ARN of the HTTP API, suitable for IAM policies or permissions. |
| stage_name | The deployed stage name. |
| route_id | The ID of the webhook route. |
| integration_id | The ID of the Lambda proxy integration. |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
# API Gateway

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.49.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.9.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.50.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_acm_certificate.cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.cert_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_api_gateway_account.account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_account) | resource |
| [aws_api_gateway_api_key.my_api_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_api_key) | resource |
| [aws_api_gateway_base_path_mapping.custom_domain_mapping](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_base_path_mapping) | resource |
| [aws_api_gateway_deployment.deployment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_domain_name.gateway_domain_name](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_domain_name) | resource |
| [aws_api_gateway_integration.lambda_integration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_method.post_method](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_resource.api_resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_rest_api.api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_stage.stage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_api_gateway_usage_plan.usage_plan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_usage_plan) | resource |
| [aws_api_gateway_usage_plan_key.usage_plan_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_usage_plan_key) | resource |
| [aws_cloudwatch_log_group.log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.apigateway_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.apigateway_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_permission.api_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_route53_record.cert_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.route53_record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_secretsmanager_secret.api_token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.api_token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [random_password.api_auth_token](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_api_gateway_description"></a> [api\_gateway\_description](#input\_api\_gateway\_description) | Description for the API Gateway | `string` | n/a | yes |
| <a name="input_api_gateway_name"></a> [api\_gateway\_name](#input\_api\_gateway\_name) | the name of the API Gateway | `string` | n/a | yes |
| <a name="input_api_path_part"></a> [api\_path\_part](#input\_api\_path\_part) | the url path for the API | `string` | n/a | yes |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | AWS account ID for the deployment context | `string` | n/a | yes |
| <a name="input_aws_lambda_arn"></a> [aws\_lambda\_arn](#input\_aws\_lambda\_arn) | Lambda function ARN | `string` | n/a | yes |
| <a name="input_aws_lambda_name"></a> [aws\_lambda\_name](#input\_aws\_lambda\_name) | Lambda function name | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region where the API Gateway is deployed | `string` | `"eu-west-2"` | no |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | The ARN of the ACM certificate to use for the custom domain (optional, will create if not provided) | `string` | `null` | no |
| <a name="input_domain_name_prefix"></a> [domain\_name\_prefix](#input\_domain\_name\_prefix) | Prefix for the custom domain name | `string` | n/a | yes |
| <a name="input_hosted_zone_name"></a> [hosted\_zone\_name](#input\_hosted\_zone\_name) | The hosted zone name for the custom domain | `string` | n/a | yes |
| <a name="input_http_method"></a> [http\_method](#input\_http\_method) | The HTTP method to use for the API Gateway | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for naming resources | `string` | n/a | yes |
| <a name="input_route53_hosted_zone_id"></a> [route53\_hosted\_zone\_id](#input\_route53\_hosted\_zone\_id) | The ID of the Route53 hosted zone | `string` | n/a | yes |
| <a name="input_secret_replication_regions"></a> [secret\_replication\_regions](#input\_secret\_replication\_regions) | List of additional regions where created secrets should be replicated | `list(string)` | n/a | yes |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | the API stage name | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_api_gateway_id"></a> [api\_gateway\_id](#output\_api\_gateway\_id) | The ID of the API Gateway |
| <a name="output_api_gateway_invoke_url"></a> [api\_gateway\_invoke\_url](#output\_api\_gateway\_invoke\_url) | The invoke URL of the API Gateway stage |
| <a name="output_api_gateway_url"></a> [api\_gateway\_url](#output\_api\_gateway\_url) | The URL of the API Gateway custom domain |
| <a name="output_api_key_id"></a> [api\_key\_id](#output\_api\_key\_id) | The ID of the API key |
| <a name="output_api_key_secret_arn"></a> [api\_key\_secret\_arn](#output\_api\_key\_secret\_arn) | The ARN of the API key secret in Secrets Manager |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
