# Elasticache

<!-- vale off -->
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_log_group.redis_engine_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.redis_slow_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_elasticache_parameter_group.bss_param_group_redis7](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_parameter_group) | resource |
| [aws_elasticache_replication_group.elasticache_replication_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_replication_group) | resource |
| [aws_elasticache_subnet_group.cache_subnet_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_subnet_group) | resource |
| [aws_iam_service_linked_role.elasticache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_security_group.cache_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_ingress_rule.ecs-inbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_iam_role.elasticache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | whether to apply changes immediately - false will apply in maintenance window | `bool` | `false` | no |
| <a name="input_auto_failover_enabled"></a> [auto\_failover\_enabled](#input\_auto\_failover\_enabled) | n/a | `any` | n/a | yes |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | The AWS account ID | `string` | n/a | yes |
| <a name="input_create_elasticache_service_role"></a> [create\_elasticache\_service\_role](#input\_create\_elasticache\_service\_role) | The service role can only be created once per account, only enable it in one stack | `bool` | `true` | no |
| <a name="input_ecs_sg_id"></a> [ecs\_sg\_id](#input\_ecs\_sg\_id) | The id of the ECS security group to enable access for | `string` | n/a | yes |
| <a name="input_elasticache_port"></a> [elasticache\_port](#input\_elasticache\_port) | Port on which Elasticache runs | `number` | `6379` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | The Elasticache engine version | `any` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD | `string` | n/a | yes |
| <a name="input_multi_az"></a> [multi\_az](#input\_multi\_az) | n/a | `any` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the resource | `string` | `"elasticache"` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | the prefix for the name which containts the environment and business unit | `string` | n/a | yes |
| <a name="input_node_type"></a> [node\_type](#input\_node\_type) | n/a | `any` | n/a | yes |
| <a name="input_notification_topic_arn"></a> [notification\_topic\_arn](#input\_notification\_topic\_arn) | Name of the SNS topic used for Elasticache alerts | `any` | n/a | yes |
| <a name="input_number_of_shards"></a> [number\_of\_shards](#input\_number\_of\_shards) | n/a | `number` | `1` | no |
| <a name="input_redis_auth_token"></a> [redis\_auth\_token](#input\_redis\_auth\_token) | Auth token for Redis cache | `any` | n/a | yes |
| <a name="input_replicas_per_node_group"></a> [replicas\_per\_node\_group](#input\_replicas\_per\_node\_group) | n/a | `number` | `2` | no |
| <a name="input_replication_group_description"></a> [replication\_group\_description](#input\_replication\_group\_description) | Description for replication group | `string` | `"Redis cache for BS-Select application"` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | The subnets that will be used for elasticache, usually private | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID for the VPC | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_redis_configuration_endpoint_address"></a> [redis\_configuration\_endpoint\_address](#output\_redis\_configuration\_endpoint\_address) | n/a |
| <a name="output_redis_configuration_endpoint_port"></a> [redis\_configuration\_endpoint\_port](#output\_redis\_configuration\_endpoint\_port) | n/a |
| <a name="output_redis_security_group_id"></a> [redis\_security\_group\_id](#output\_redis\_security\_group\_id) | n/a |
<!-- END_TF_DOCS -->
<!-- vale on -->
