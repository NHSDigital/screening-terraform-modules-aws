# ElastiCache

NHS Screening wrapper around the community
[`terraform-aws-modules/elasticache/aws`](https://registry.terraform.io/modules/terraform-aws-modules/elasticache/aws/latest)
module that enforces the platform's baseline controls and consumes the shared `context.tf` for naming and tagging.

Supports **Valkey** (recommended), **Redis** (with cluster mode and replication), and **Memcached** engines with configurable high-availability options for session storage and caching workloads.

## What this module enforces

|Control|How it is enforced|
|---|---|
|Encryption in transit (TLS)|`transit_encryption_enabled = true` enforced; `auth_token` required for Redis/Valkey|
|Encryption at rest|`at_rest_encryption_enabled = true` enforced; KMS key configurable|
|No public access|Deployed in private subnets; security groups restrict ingress to specified sources|
|Multi-AZ availability|`multi_az_enabled = true` by default; `automatic_failover_enabled = true` by default|
|High availability (Redis/Valkey)|Cluster mode with configurable replicas per shard; all nodes store full dataset|
|Logging|Engine logs and slow logs delivered to CloudWatch with configurable retention|
|Backup & snapshots|Configurable retention (default 5 days); final snapshot on deletion|
|Maintenance windows|Configurable UTC window; updates applied during window (not immediately)|
|All resources tagged|Via `module.this.tags`; naming derived from context module|

## Supported Engines

|Engine|Versions|Cluster Mode|Serverless|Failover|Recommended Use|
|---|---|---|---|---|---|
|**Valkey** (recommended)|7.2, 8.0|✓ Sharded|✓|Automatic|Primary choice; Redis-compatible; better governance|
|**Redis**|7.0, 7.1, 7.2, 6.x|✓ Sharded|✓|Automatic|Legacy deployments; same features as Valkey|
|**Memcached**|1.6.x, 1.7.x|✗ Single node|✗|None|Stateless caching; not recommended for session storage|

## Node Types

- **t3/t4g (burstable)**: `cache.t3.small`, `cache.t4g.medium` — development, low-traffic
- **r6g/r7g (memory-optimized)**: `cache.r6g.large`, `cache.r7g.xlarge` — production, steady-state
- **m6g/m7g (general)**: `cache.m6g.large`, `cache.m7g.large` — balanced price/performance
- **r6gd/r7gd (with local NVMe)**: Enable data tiering for cost savings (Redis 6.0+)

## Usage

### 1. Valkey — replication group, cluster mode (production default)

Recommended starting point for session storage. Multi-AZ, 1 shard with 2 replicas.
Security group supplied externally from the `security-group` module.

```hcl
module "session_cache" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/elasticache?ref=main"

  service     = "bcss"
  project     = "platform"
  environment = "prod"
  name        = "session"

  deployment_mode = "replication_group"
  engine          = "valkey"
  engine_version  = "8.0"
  node_type       = "cache.r7g.large"

  cluster_mode_enabled    = true
  num_node_groups         = 1
  replicas_per_node_group = 2
  multi_az_enabled        = true

  subnet_ids            = module.vpc.private_subnet_ids
  create_security_group = false
  security_group_ids    = [module.cache_sg.id]

  auth_token  = data.aws_secretsmanager_secret_version.cache_auth.secret_string
  kms_key_arn = module.cache_kms.key_arn

  notification_topic_arn = module.alerting.topic_arn
}
```

### 2. Valkey — standalone cluster (non-production cost saving)

Single-node cluster for dev/test environments where HA is not required.

```hcl
module "session_cache_dev" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/elasticache?ref=main"

  service     = "bcss"
  project     = "platform"
  environment = "dev"
  name        = "session"

  deployment_mode = "cluster"
  engine          = "valkey"
  engine_version  = "8.0"
  node_type       = "cache.t4g.small"
  num_cache_nodes = 1

  subnet_ids            = module.vpc.private_subnet_ids
  create_security_group = false
  security_group_ids    = [module.cache_sg.id]

  auth_token = data.aws_secretsmanager_secret_version.cache_auth.secret_string

  # Reduce snapshot retention for non-prod
  snapshot_retention_days = 1
}
```

### 3. Valkey — serverless (auto-scaling, no node provisioning)

No capacity planning required; scales on demand. No `node_type` needed.

```hcl
module "session_cache_serverless" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/elasticache?ref=main"

  service     = "bcss"
  project     = "reports"
  environment = "prod"
  name        = "cache"

  deployment_mode = "serverless"
  engine          = "valkey"
  engine_version  = "8.0"

  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.cache_sg.id]

  kms_key_arn = module.cache_kms.key_arn

  # Optional hard limits; omit for fully elastic scaling
  serverless_cache_usage_limits = {
    data_storage    = { maximum = 50, unit = "GB" }
    ecpu_per_second = { maximum = 5000 }
  }
}
```

### 4. Redis — replication group, simple replication (no sharding)

Single primary with replicas; no cluster mode. Suitable for workloads that need
replication but not horizontal key-space sharding.

```hcl
module "content_cache" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/elasticache?ref=main"

  service     = "bcss"
  project     = "web"
  environment = "prod"
  name        = "content"

  deployment_mode      = "replication_group"
  engine               = "redis"
  engine_version       = "7.2"
  node_type            = "cache.r7g.large"
  cluster_mode_enabled = false
  num_cache_nodes      = 3  # 1 primary + 2 replicas
  multi_az_enabled     = true

  subnet_ids            = module.vpc.private_subnet_ids
  create_security_group = false
  security_group_ids    = [module.cache_sg.id]

  kms_key_arn = module.cache_kms.key_arn
  auth_token  = data.aws_secretsmanager_secret_version.cache_auth.secret_string

  snapshot_window         = "02:00-03:00"
  snapshot_retention_days = 14
  notification_topic_arn  = module.alerting.topic_arn
  maintenance_window      = "sun:03:00-sun:04:00"
}
```

### 5. Redis — replication group, cluster mode with multiple shards

Horizontally sharded for large datasets or high throughput.
Uses data tiering on r7gd instances for cost-efficient cold-data storage.

```hcl
module "large_cache" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/elasticache?ref=main"

  service     = "bcss"
  project     = "platform"
  environment = "prod"
  name        = "large"

  deployment_mode         = "replication_group"
  engine                  = "redis"
  engine_version          = "7.2"
  node_type               = "cache.r7gd.xlarge"
  cluster_mode_enabled    = true
  num_node_groups         = 3
  replicas_per_node_group = 2
  multi_az_enabled        = true
  data_tiering_enabled    = true

  subnet_ids            = module.vpc.private_subnet_ids
  create_security_group = false
  security_group_ids    = [module.cache_sg.id]

  kms_key_arn = module.cache_kms.key_arn
  auth_token  = data.aws_secretsmanager_secret_version.cache_auth.secret_string

  snapshot_retention_days = 7
  notification_topic_arn  = module.alerting.topic_arn
}
```

### 6. Redis — serverless

```hcl
module "redis_serverless" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/elasticache?ref=main"

  service     = "bcss"
  project     = "api"
  environment = "prod"
  name        = "rate-limit"

  deployment_mode = "serverless"
  engine          = "redis"
  engine_version  = "7.2"

  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.cache_sg.id]

  kms_key_arn = module.cache_kms.key_arn
}
```

### 7. Memcached — cross-AZ cluster (stateless page caching)

Memcached only supports `deployment_mode = "cluster"`. No replication, no snapshots.
Use `az_mode = "cross-az"` with `num_cache_nodes >= 2` for redundancy.

```hcl
module "page_cache" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/elasticache?ref=main"

  service     = "bcss"
  project     = "web"
  environment = "prod"
  name        = "page-cache"

  deployment_mode = "cluster"
  engine          = "memcached"
  engine_version  = "1.6.22"
  node_type       = "cache.t4g.medium"
  num_cache_nodes = 2
  az_mode         = "cross-az"

  subnet_ids            = module.vpc.private_subnet_ids
  create_security_group = false
  security_group_ids    = [module.cache_sg.id]

  # No auth_token, kms_key_arn, or snapshots for Memcached
}
```

## Conventions

- **Deployment mode**: `replication_group` (default) for production HA; `cluster` for non-prod single/multi-node; `serverless` for auto-scaling with no node management.
- **Naming**: Resource names are derived from `module.this.id`. Use `attributes` and `tags` to differentiate multiple instances.
- **Security groups**: Pass existing SG IDs via `security_group_ids` (from the `security-group` module). Set `create_security_group = true` with `security_group_rules` to create one inline.
- **KMS**: Pass `kms_key_arn` from the `kms` module for customer-managed encryption. Omit for AWS-managed (still enforced at rest).
- **Encryption**: Both in-transit (TLS) and at-rest encryption are **enforced and cannot be disabled**. Auth tokens required for Redis/Valkey.
- **Cluster mode**: Enabled by default within `replication_group` mode. Each shard holds the full dataset; scales out by adding shards.
- **Replicas**: Default 2 per shard. Set `replicas_per_node_group = 0` only for non-critical single-node deployments.
- **Logging**: Both slow-log and engine-log delivered to CloudWatch with 365-day retention by default. Override via `log_delivery_configuration`. Pre-create log groups via the CloudWatch module for KMS encryption.
- **Snapshots**: Redis/Valkey only (not Memcached). Default 5-day retention. Set `final_snapshot_identifier_prefix` to preserve state on deletion.
- **Maintenance**: Applied during the configured window (default: Sunday 03:00–05:00 UTC). Use `apply_immediately = true` for emergency patches only.

## What this module does NOT do

- Create KMS keys. Use the `kms` module and pass the ARN via `kms_key_arn`.
- Create security groups. Use the `security-group` module and pass the ID via `security_group_ids`, or set `create_security_group = true` to create one inline via the upstream module.
- Create CloudWatch log groups with custom KMS encryption. Pass pre-created group names via `log_delivery_configuration`. See the TODO comment in [main.tf](main.tf) for the pattern.
- Manage EC2 instances or ECS task definitions; point them at the cache endpoint outputs.
- Configure client-side replica read preference. That is an application concern.
- Perform failover testing or validate backup/restore procedures. Validate separately in lower environments.
- Manage DNS aliases or application-level caching strategies.
- Auto-scale server-full deployments based on memory pressure. Monitor CloudWatch metrics and resize manually.

## Security Checklist

Before deploying, verify:

- [ ] Encryption in transit enforced (TLS) — hardcoded, no action needed
- [ ] Encryption at rest enforced — hardcoded, no action needed
- [ ] No public access — confirm private subnets only in `subnet_ids`
- [ ] Multi-AZ enabled — set `multi_az_enabled = true` for production
- [ ] Automatic failover enabled — set `automatic_failover_enabled = true` for production
- [ ] Auth token supplied for Redis/Valkey — source from AWS Secrets Manager
- [ ] Security group configured — supply via `security_group_ids` or set `create_security_group = true`
- [ ] Logging configured — review `log_delivery_configuration` default (365-day retention)
- [ ] Snapshot retention set — review `snapshot_retention_days` (default: 5)
- [ ] Maintenance window configured for low-traffic period
- [ ] SNS topic supplied for failover/maintenance notifications
- [ ] All context labels set (`service`, `project`, `environment`, `name`)

## Outputs

|Output|Mode|Description|
|---|---|---|
|`id`|all|Active deployment mode|
|`replication_group_id`|replication_group|Replication group ID|
|`replication_group_arn`|replication_group|Replication group ARN|
|`primary_endpoint_address`|replication_group|Writer endpoint|
|`reader_endpoint_address`|replication_group|Read-only endpoint|
|`configuration_endpoint_address`|replication_group|Cluster-mode shard endpoint|
|`member_clusters`|replication_group|List of member node IDs|
|`port`|replication_group|Listening port|
|`cluster_arn`|cluster|Standalone cluster ARN|
|`cluster_address`|cluster|Cluster DNS name / primary endpoint|
|`cluster_configuration_endpoint`|cluster|Memcached auto-discovery endpoint|
|`serverless_arn`|serverless|Serverless cache ARN|
|`serverless_endpoint`|serverless|Serverless connection endpoint|
|`serverless_reader_endpoint`|serverless|Serverless reader endpoint|
|`security_group_id`|all|First caller-managed SG ID|
|`cloudwatch_log_group_name`|replication_group, cluster|Primary log group name|
|`cloudwatch_log_group_arn`|replication_group, cluster|Primary log group ARN|
|`snapshot_window`|all|Snapshot window|
|`maintenance_window`|all|Maintenance window|

## Exemplar Modules

Reference these for patterns:

- [s3-bucket](../s3-bucket) — full wrapper with comprehensive security
- [kms](../kms) — customer-managed key creation
- [security-group](../security-group) — security group patterns
- [sns](../sns) — notification topic setup

## Terraform Validation

```bash
# Format
terraform fmt -recursive infrastructure/modules/elasticache

# Initialize (required for validate)
terraform -chdir=infrastructure/modules/elasticache init

# Validate
terraform -chdir=infrastructure/modules/elasticache validate
```

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.93 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_elasticache"></a> [elasticache](#module\_elasticache) | terraform-aws-modules/elasticache/aws | 1.11.0 |
| <a name="module_elasticache_serverless"></a> [elasticache\_serverless](#module\_elasticache\_serverless) | terraform-aws-modules/elasticache/aws//modules/serverless-cache | 1.11.0 |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_application_role"></a> [application\_role](#input\_application\_role) | The role the application is performing | `string` | `"General"` | no |
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | Apply parameter changes immediately instead of during the maintenance window. Default: false (safer, batches changes). | `bool` | `false` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_auth_token"></a> [auth\_token](#input\_auth\_token) | Authentication token for Redis/Valkey clusters (16-128 characters, alphanumeric only).<br/>Required for Redis/Valkey; ignored for Memcached.<br/>Rotate regularly; use AWS Secrets Manager or similar. | `string` | `null` | no |
| <a name="input_auto_minor_version_upgrade"></a> [auto\_minor\_version\_upgrade](#input\_auto\_minor\_version\_upgrade) | Enable automatic minor version upgrades during maintenance window. | `bool` | `true` | no |
| <a name="input_automatic_failover_enabled"></a> [automatic\_failover\_enabled](#input\_automatic\_failover\_enabled) | Enable automatic failover for Redis/Valkey replication groups. Default: true | `bool` | `true` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_az_mode"></a> [az\_mode](#input\_az\_mode) | Availability zone mode for standalone clusters (deployment\_mode = "cluster").<br/>- single-az (default): all nodes in one AZ.<br/>- cross-az: nodes spread across multiple AZs. Required for Memcached multi-node clusters.<br/>Ignored for replication\_group and serverless deployment modes. | `string` | `null` | no |
| <a name="input_cluster_mode_enabled"></a> [cluster\_mode\_enabled](#input\_cluster\_mode\_enabled) | Enable cluster mode (sharding). When true, all nodes in each shard store the full dataset.<br/>Allows horizontal scaling via multiple shards.<br/>Default: true (recommended for production). | `bool` | `true` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "project": null,<br/>  "regex_replace_chars": null,<br/>  "region": null,<br/>  "service": null,<br/>  "stack": null,<br/>  "tags": {},<br/>  "terraform_source": null,<br/>  "workspace": null<br/>}</pre> | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | When false (default), supply existing security group IDs via security\_group\_ids — e.g.<br/>from this repo's security-group module (feature/BCSS-23606-security-group-module).<br/>When true, the upstream module creates a security group in var.vpc\_id using the<br/>rules defined in security\_group\_rules. vpc\_id is required in this case. | `bool` | `false` | no |
| <a name="input_data_classification"></a> [data\_classification](#input\_data\_classification) | Used to identify the data classification of the resource, e.g 1-5 | `string` | `"n/a"` | no |
| <a name="input_data_tiering_enabled"></a> [data\_tiering\_enabled](#input\_data\_tiering\_enabled) | Enable data tiering (Redis 6.0+ with r6gd/r7gd instances only).<br/>Allows overflow data to be stored on local NVMe SSD for cost savings.<br/>Default: false | `bool` | `false` | no |
| <a name="input_data_type"></a> [data\_type](#input\_data\_type) | The tag data\_type | `string` | `"None"` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_deployment_mode"></a> [deployment\_mode](#input\_deployment\_mode) | Controls which ElastiCache resource type is created.<br/>- replication\_group (default): HA replication group with optional cluster mode and Multi-AZ.<br/>  Supports Valkey, Redis, and Memcached. Recommended for production and session storage.<br/>- cluster: Standalone single/multi-node cluster without replication.<br/>  Useful for development, non-prod cost saving, or Memcached deployments.<br/>- serverless: Auto-scaling serverless cache. Valkey and Redis only.<br/>  No node provisioning required; capacity scales on demand.<br/>Note: Memcached only supports deployment\_mode = "cluster". | `string` | `"replication_group"` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>    format = string<br/>    labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_engine"></a> [engine](#input\_engine) | ElastiCache engine. Supported: 'valkey' (recommended), 'redis', 'memcached'. | `string` | `"valkey"` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | Engine version.<br/>- Valkey: 7.2, 8.0<br/>- Redis: 7.0, 7.1, 7.2 (or 6.x for older deployments; 6.0+ required for data tiering)<br/>- Memcached: 1.6.x, 1.7.x | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_final_snapshot_identifier_prefix"></a> [final\_snapshot\_identifier\_prefix](#input\_final\_snapshot\_identifier\_prefix) | Prefix for the final snapshot name. When deletion is requested, a snapshot is created before deletion. Leave null to skip final snapshot. | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | Optional KMS key ARN for encryption at rest. When null, AWS-managed encryption is used.<br/>To use a specific customer-managed KMS key, provide the ARN.<br/>Encryption at rest is always enforced. | `string` | `null` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_log_delivery_configuration"></a> [log\_delivery\_configuration](#input\_log\_delivery\_configuration) | Log delivery configuration passed to the upstream module.<br/>By default, both slow-log and engine-log are sent to CloudWatch Logs with<br/>365-day retention and JSON format. The upstream module creates the log groups.<br/>To pre-create log groups externally (e.g. via the cloudwatch module for KMS-encrypted<br/>groups or custom retention), set create\_cloudwatch\_log\_group = false and supply<br/>the destination group name per entry. Set to {} to disable all logging. | `any` | <pre>{<br/>  "engine-log": {<br/>    "cloudwatch_log_group_retention_in_days": 365,<br/>    "destination_type": "cloudwatch-logs",<br/>    "log_format": "json"<br/>  },<br/>  "slow-log": {<br/>    "cloudwatch_log_group_retention_in_days": 365,<br/>    "destination_type": "cloudwatch-logs",<br/>    "log_format": "json"<br/>  }<br/>}</pre> | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | Time window for routine maintenance (UTC).<br/>Format: ddd:hh24:mi-ddd:hh24:mi (e.g. 'sun:03:00-sun:05:00').<br/>Default: Sunday 03:00-05:00 UTC. | `string` | `"sun:03:00-sun:05:00"` | no |
| <a name="input_multi_az_enabled"></a> [multi\_az\_enabled](#input\_multi\_az\_enabled) | Enable Multi-AZ failover. Recommended for production deployments. | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_node_type"></a> [node\_type](#input\_node\_type) | Node instance type.<br/>- Valkey/Redis: cache.t3.*, cache.t4g.*, cache.r6g.*, cache.r7g.*, cache.m6g.*, cache.m7g.*, etc.<br/>- Memcached: cache.t3.*, cache.t4g.*, cache.m6g.*, etc.<br/><br/>Use cache.t3.small or cache.t4g.small for development; cache.r7g.* for production. | `string` | `null` | no |
| <a name="input_notification_topic_arn"></a> [notification\_topic\_arn](#input\_notification\_topic\_arn) | Optional SNS topic ARN for ElastiCache event notifications (failovers, updates, maintenance). Leave null to disable. | `string` | `null` | no |
| <a name="input_num_cache_nodes"></a> [num\_cache\_nodes](#input\_num\_cache\_nodes) | Number of cache nodes in the cluster. For non-cluster mode only; ignored when cluster\_mode\_enabled = true. | `number` | `2` | no |
| <a name="input_num_node_groups"></a> [num\_node\_groups](#input\_num\_node\_groups) | Number of shards in cluster mode. Only used when cluster\_mode\_enabled = true. Minimum 1, maximum 500. | `number` | `1` | no |
| <a name="input_on_off_pattern"></a> [on\_off\_pattern](#input\_on\_off\_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_port"></a> [port](#input\_port) | Port on which ElastiCache listens. Default: 6379 for Redis/Valkey, 11211 for Memcached. Must match between clients and cache. | `number` | `6379` | no |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_replicas_per_node_group"></a> [replicas\_per\_node\_group](#input\_replicas\_per\_node\_group) | Number of replicas per shard (cluster mode) or per replication group (disabled cluster mode).<br/>Each replica stores a copy of the dataset for high availability and failover.<br/>Default: 2 (recommended for multi-AZ production deployments). | `number` | `2` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | List of existing security group IDs to associate with the cache.<br/>Required when create\_security\_group = false.<br/>Typically sourced from this repo's security-group module. | `list(string)` | `[]` | no |
| <a name="input_security_group_rules"></a> [security\_group\_rules](#input\_security\_group\_rules) | Map of ingress and egress rules for the upstream-managed security group.<br/>Only used when create\_security\_group = true.<br/>See the upstream module documentation for the full shape of each rule entry. | `any` | `{}` | no |
| <a name="input_serverless_cache_usage_limits"></a> [serverless\_cache\_usage\_limits](#input\_serverless\_cache\_usage\_limits) | Optional capacity limits for serverless caches (deployment\_mode = "serverless").<br/>Leave as {} for on-demand auto-scaling with no hard limits. Example:<br/>  serverless\_cache\_usage\_limits = {<br/>    data\_storage    = { maximum = 100, unit = "GB" }<br/>    ecpu\_per\_second = { maximum = 5000 }<br/>  } | `any` | `{}` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_snapshot_retention_days"></a> [snapshot\_retention\_days](#input\_snapshot\_retention\_days) | Number of days to retain automated snapshots (Redis/Valkey only).<br/>Memcached does not support snapshots.<br/>Range: 1 to 35 days. Default: 5 days. | `number` | `5` | no |
| <a name="input_snapshot_window"></a> [snapshot\_window](#input\_snapshot\_window) | Time window in UTC when snapshots are taken (Redis/Valkey only).<br/>Format: hh24:mi-hh24:mi (e.g. '03:00-05:00'). Default: '03:00-05:00' | `string` | `"03:00-05:00"` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs for the ElastiCache subnet group.<br/>Should be private subnets across multiple AZs for high availability.<br/>Minimum: 2 subnets (different AZs); recommended for multi-AZ deployments. | `list(string)` | n/a | yes |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to the caller module path when not set. | `string` | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID. Required when create\_security\_group = true; otherwise optional. | `string` | `null` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | ARN of the primary CloudWatch log group created by the upstream module. |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | Name of the primary CloudWatch log group created by the upstream module. |
| <a name="output_cluster_address"></a> [cluster\_address](#output\_cluster\_address) | DNS name of the cache cluster (Memcached) or primary endpoint. |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | ARN of the standalone ElastiCache cluster. |
| <a name="output_cluster_configuration_endpoint"></a> [cluster\_configuration\_endpoint](#output\_cluster\_configuration\_endpoint) | Configuration endpoint for Memcached clusters (auto-discovery). |
| <a name="output_configuration_endpoint_address"></a> [configuration\_endpoint\_address](#output\_configuration\_endpoint\_address) | Configuration endpoint for cluster-mode replication groups (connects to all shards). |
| <a name="output_deployment_mode"></a> [deployment\_mode](#output\_deployment\_mode) | Active deployment mode: replication\_group, cluster, or serverless. |
| <a name="output_maintenance_window"></a> [maintenance\_window](#output\_maintenance\_window) | Maintenance window (UTC). |
| <a name="output_member_clusters"></a> [member\_clusters](#output\_member\_clusters) | List of member node IDs in the replication group. |
| <a name="output_port"></a> [port](#output\_port) | Port on which the ElastiCache resource listens. |
| <a name="output_primary_endpoint_address"></a> [primary\_endpoint\_address](#output\_primary\_endpoint\_address) | Primary (writer) endpoint for the replication group. |
| <a name="output_reader_endpoint_address"></a> [reader\_endpoint\_address](#output\_reader\_endpoint\_address) | Reader endpoint (load-balanced across replicas) for the replication group. |
| <a name="output_replication_group_arn"></a> [replication\_group\_arn](#output\_replication\_group\_arn) | ARN of the ElastiCache replication group. |
| <a name="output_replication_group_id"></a> [replication\_group\_id](#output\_replication\_group\_id) | ID of the ElastiCache replication group. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | First security group ID associated with the cache.<br/>When create\_security\_group = false this is security\_group\_ids[0] (caller-managed).<br/>When create\_security\_group = true, query the SG from the security-group module instead. |
| <a name="output_serverless_arn"></a> [serverless\_arn](#output\_serverless\_arn) | ARN of the serverless cache. |
| <a name="output_serverless_endpoint"></a> [serverless\_endpoint](#output\_serverless\_endpoint) | Connection endpoint (address and port) for the serverless cache. |
| <a name="output_serverless_reader_endpoint"></a> [serverless\_reader\_endpoint](#output\_serverless\_reader\_endpoint) | Reader endpoint for the serverless cache. |
| <a name="output_snapshot_window"></a> [snapshot\_window](#output\_snapshot\_window) | Time window for automated snapshots (UTC). |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
