# ECS-Cluster

<!-- vale off -->
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_metric_alarm.task_cpu_utilization_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.task_memory_utilization_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_ecs_cluster.ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_iam_service_linked_role.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_security_group.ecs_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.ecs_all_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_iam_role.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_sns_topic.alert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/sns_topic) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_account_id"></a> [aws_account_id](#input_aws_account_id) | The AWS account ID | `string` | n/a | yes |
| <a name="input_container_port"></a> [container_port](#input_container_port) | n/a | `number` | `4000` | no |
| <a name="input_create_ecs_service_role"></a> [create_ecs_service_role](#input_create_ecs_service_role) | The service role can only be created once per account, only enable it in one stack | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input_environment) | The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input_name) | the unique name of the resource | `string` | `"ecs"` | no |
| <a name="input_name_prefix"></a> [name_prefix](#input_name_prefix) | The account, environment etc | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id) | id of the vpc | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ecs_cluster_arn"></a> [ecs_cluster_arn](#output_ecs_cluster_arn) | n/a |
| <a name="output_ecs_cluster_name"></a> [ecs_cluster_name](#output_ecs_cluster_name) | n/a |
| <a name="output_ecs_sg_id"></a> [ecs_sg_id](#output_ecs_sg_id) | n/a |
<!-- END_TF_DOCS -->
<!-- vale on -->
