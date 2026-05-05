# API Gateway

<!-- vale off -->
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

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
|------|-------------|------|---------|:--------:|
| <a name="input_api_gateway_description"></a> [api_gateway_description](#input_api_gateway_description) | Description for the API Gateway | `string` | n/a | yes |
| <a name="input_api_gateway_name"></a> [api_gateway_name](#input_api_gateway_name) | the name of the API Gateway | `any` | n/a | yes |
| <a name="input_api_path_part"></a> [api_path_part](#input_api_path_part) | the url path for the API | `any` | n/a | yes |
| <a name="input_aws_account_id"></a> [aws_account_id](#input_aws_account_id) | n/a | `any` | n/a | yes |
| <a name="input_aws_lambda_arn"></a> [aws_lambda_arn](#input_aws_lambda_arn) | n/a | `any` | n/a | yes |
| <a name="input_aws_lambda_name"></a> [aws_lambda_name](#input_aws_lambda_name) | n/a | `any` | n/a | yes |
| <a name="input_aws_region"></a> [aws_region](#input_aws_region) | The AWS region where the API Gateway is deployed | `string` | `"eu-west-2"` | no |
| <a name="input_certificate_arn"></a> [certificate_arn](#input_certificate_arn) | The ARN of the ACM certificate to use for the custom domain (optional, will create if not provided) | `string` | `null` | no |
| <a name="input_domain_name_prefix"></a> [domain_name_prefix](#input_domain_name_prefix) | Prefix for the custom domain name | `string` | n/a | yes |
| <a name="input_hosted_zone_name"></a> [hosted_zone_name](#input_hosted_zone_name) | The hosted zone name for the custom domain | `string` | n/a | yes |
| <a name="input_http_method"></a> [http_method](#input_http_method) | The HTTP method to use for the API Gateway | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name_prefix](#input_name_prefix) | Prefix for naming resources | `string` | n/a | yes |
| <a name="input_route53_hosted_zone_id"></a> [route53_hosted_zone_id](#input_route53_hosted_zone_id) | The ID of the Route53 hosted zone | `string` | n/a | yes |
| <a name="input_secret_replication_regions"></a> [secret_replication_regions](#input_secret_replication_regions) | List of additional regions where created secrets should be replicated | `list(string)` | n/a | yes |
| <a name="input_stage_name"></a> [stage_name](#input_stage_name) | the API stage name | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_gateway_id"></a> [api_gateway_id](#output_api_gateway_id) | The ID of the API Gateway |
| <a name="output_api_gateway_invoke_url"></a> [api_gateway_invoke_url](#output_api_gateway_invoke_url) | The invoke URL of the API Gateway stage |
| <a name="output_api_gateway_url"></a> [api_gateway_url](#output_api_gateway_url) | The URL of the API Gateway custom domain |
| <a name="output_api_key_id"></a> [api_key_id](#output_api_key_id) | The ID of the API key |
| <a name="output_api_key_secret_arn"></a> [api_key_secret_arn](#output_api_key_secret_arn) | The ARN of the API key secret in Secrets Manager |
<!-- END_TF_DOCS -->
<!-- vale on -->
