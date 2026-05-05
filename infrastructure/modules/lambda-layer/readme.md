# Lambda layer

<!-- vale off -->
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider_aws) | n/a |
| <a name="provider_null"></a> [null](#provider_null) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_lambda_layer_version.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_layer_version) | resource |
| [null_resource.build_lambda_layer](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_compatible_runtimes"></a> [compatible_runtimes](#input_compatible_runtimes) | Compatible Python runtimes for the Lambda layer | `list(string)` | <pre>[<br/>  "python3.12"<br/>]</pre> | no |
| <a name="input_description"></a> [description](#input_description) | The description for the Lambda layer | `string` | n/a | yes |
| <a name="input_layer_name"></a> [layer_name](#input_layer_name) | The name of the Lambda layer | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name_prefix](#input_name_prefix) | the prefix standard | `string` | n/a | yes |
| <a name="input_source_path"></a> [source_path](#input_source_path) | The path of the stored layer zip file | `string` | `"../../layers"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_layer_arn"></a> [layer_arn](#output_layer_arn) | n/a |
<!-- END_TF_DOCS -->

<!-- vale on -->
