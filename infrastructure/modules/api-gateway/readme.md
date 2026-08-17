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
