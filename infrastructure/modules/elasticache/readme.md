# Elasticache

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
|------|-------------|------|---------|:--------:|
| <a name="input_apply_immediately"></a> [apply_immediately](#input_apply_immediately) | whether to apply changes immediately - false will apply in maintenance window | `bool` | `false` | no |
| <a name="input_auto_failover_enabled"></a> [auto_failover_enabled](#input_auto_failover_enabled) | n/a | `any` | n/a | yes |
| <a name="input_aws_account_id"></a> [aws_account_id](#input_aws_account_id) | The AWS account ID | `string` | n/a | yes |
| <a name="input_create_elasticache_service_role"></a> [create_elasticache_service_role](#input_create_elasticache_service_role) | The service role can only be created once per account, only enable it in one stack | `bool` | `true` | no |
| <a name="input_ecs_sg_id"></a> [ecs_sg_id](#input_ecs_sg_id) | The id of the ECS security group to enable access for | `string` | n/a | yes |
| <a name="input_elasticache_port"></a> [elasticache_port](#input_elasticache_port) | Port on which Elasticache runs | `number` | `6379` | no |
| <a name="input_engine_version"></a> [engine_version](#input_engine_version) | The Elasticache engine version | `any` | n/a | yes |
| <a name="input_environment"></a> [environment](#input_environment) | The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD | `string` | n/a | yes |
| <a name="input_multi_az"></a> [multi_az](#input_multi_az) | n/a | `any` | n/a | yes |
| <a name="input_name"></a> [name](#input_name) | The name of the resource | `string` | `"elasticache"` | no |
| <a name="input_name_prefix"></a> [name_prefix](#input_name_prefix) | the prefix for the name which containts the environment and business unit | `string` | n/a | yes |
| <a name="input_node_type"></a> [node_type](#input_node_type) | n/a | `any` | n/a | yes |
| <a name="input_notification_topic_arn"></a> [notification_topic_arn](#input_notification_topic_arn) | Name of the SNS topic used for Elasticache alerts | `any` | n/a | yes |
| <a name="input_number_of_shards"></a> [number_of_shards](#input_number_of_shards) | n/a | `number` | `1` | no |
| <a name="input_redis_auth_token"></a> [redis_auth_token](#input_redis_auth_token) | Auth token for Redis cache | `any` | n/a | yes |
| <a name="input_replicas_per_node_group"></a> [replicas_per_node_group](#input_replicas_per_node_group) | n/a | `number` | `2` | no |
| <a name="input_replication_group_description"></a> [replication_group_description](#input_replication_group_description) | Description for replication group | `string` | `"Redis cache for BS-Select application"` | no |
| <a name="input_subnet_ids"></a> [subnet_ids](#input_subnet_ids) | The subnets that will be used for elasticache, usually private | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id) | The ID for the VPC | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_redis_configuration_endpoint_address"></a> [redis_configuration_endpoint_address](#output_redis_configuration_endpoint_address) | n/a |
| <a name="output_redis_configuration_endpoint_port"></a> [redis_configuration_endpoint_port](#output_redis_configuration_endpoint_port) | n/a |
| <a name="output_redis_security_group_id"></a> [redis_security_group_id](#output_redis_security_group_id) | n/a |
<!-- END_TF_DOCS -->
<!-- vale on -->
