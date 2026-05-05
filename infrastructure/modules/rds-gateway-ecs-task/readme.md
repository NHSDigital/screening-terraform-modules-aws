# rds-gateway-ecs-task
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
| [aws_cloudwatch_log_group.log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_service.ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_policy.ecs_execution_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ecs_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ecs_task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group.ecs_task_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.allow_all_outbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.rds_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_iam_policy_document.assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_account_id"></a> [aws_account_id](#input_aws_account_id) | The aws account id | `string` | n/a | yes |
| <a name="input_ecs_cluster_name"></a> [ecs_cluster_name](#input_ecs_cluster_name) | The ECS cluster name | `string` | n/a | yes |
| <a name="input_image_name"></a> [image_name](#input_image_name) | The image name for the ECS task | `string` | `"public.ecr.aws/docker/library/busybox:stable"` | no |
| <a name="input_name_prefix"></a> [name_prefix](#input_name_prefix) | The account, environment etc | `string` | n/a | yes |
| <a name="input_private_subnet_ids"></a> [private_subnet_ids](#input_private_subnet_ids) | List of private subnet IDs | `list(string)` | n/a | yes |
| <a name="input_rds_sg_id"></a> [rds_sg_id](#input_rds_sg_id) | The security group ID of the RDS instance | `string` | n/a | yes |
| <a name="input_replica_task_count"></a> [replica_task_count](#input_replica_task_count) | The number of task replicas to run | `number` | `1` | no |
| <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id) | id of the vpc | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
<!-- vale on -->
