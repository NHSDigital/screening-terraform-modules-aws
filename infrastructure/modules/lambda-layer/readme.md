# Lambda layer

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.47.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.50.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.3.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_lambda_layer_version.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_layer_version) | resource |
| [null_resource.build_lambda_layer](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_compatible_runtimes"></a> [compatible\_runtimes](#input\_compatible\_runtimes) | Compatible Python runtimes for the Lambda layer | `list(string)` | <pre>[<br/>  "python3.12"<br/>]</pre> | no |
| <a name="input_description"></a> [description](#input\_description) | The description for the Lambda layer | `string` | n/a | yes |
| <a name="input_layer_name"></a> [layer\_name](#input\_layer\_name) | The name of the Lambda layer | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | the prefix standard | `string` | n/a | yes |
| <a name="input_source_path"></a> [source\_path](#input\_source\_path) | The path of the stored layer zip file | `string` | `"../../layers"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_layer_arn"></a> [layer\_arn](#output\_layer\_arn) | ARN of the published Lambda layer version |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
