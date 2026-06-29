# ElastiCache Redis/Valkey

NHS Screening wrapper around the community
[`terraform-aws-modules/elasticache/aws`](https://registry.terraform.io/modules/terraform-aws-modules/elasticache/aws/latest)
module for ElastiCache replication groups. It consumes the shared `context.tf` for
naming and tagging, keeps the interface close to upstream, and adds a few
defaults that are useful for the platform.

<!-- vale Vale.Spelling = NO -->

## What this module does

* Provisions a Valkey or Redis OSS replication group using the upstream ElastiCache module.
* Creates a subnet group and parameter group by default.
* Security groups must be created externally (e.g. using the `security-group` module) and passed via `security_group_ids`.
* Derives `replication_group_id` from the shared context when you do not set it.
* Defaults new deployments to `engine = "valkey"`.
* Derives `parameter_group_family` from `engine` and `engine_version` when possible.
* Enforces encryption at rest and in transit (cannot be overridden).
* Rejects Redis OSS major versions 4 and 5 so new callers do not encode an EOL engine choice.
* Sends slow logs to CloudWatch Logs by default unless you override
  `log_delivery_configuration`.

## Important boundary

This wrapper can provision a Valkey-backed ElastiCache replication group, but it does not prove
application compatibility. If an existing connector or client library is tightly coupled to older
Redis OSS behaviour, that compatibility check still needs to happen in the consuming service.

## Usage

### Minimal Valkey replication group

```hcl
module "redis" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/elasticache-redis?ref=main"

  service     = "bcss"
  project     = "screening"
  environment = "dev"
  name        = "redis"

  engine         = "valkey"
  node_type      = "cache.t4g.small"
  engine_version = "7.2"
  auth_token     = "replace-with-a-secret-value"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  security_group_rules = {
    ingress_vpc = {
      description = "VPC traffic"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }
}
```

### Highly available non-clustered Valkey

```hcl
module "redis" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/elasticache-redis?ref=main"

  service     = "bcss"
  project     = "screening"
  environment = "prod"
  name        = "redis"

  engine                      = "valkey"
  node_type                   = "cache.r7g.large"
  engine_version              = "7.2"
  auth_token                  = "replace-with-a-secret-value"
  num_cache_clusters          = 2
  automatic_failover_enabled  = true
  multi_az_enabled            = true
  maintenance_window          = "sun:05:00-sun:09:00"
  snapshot_retention_limit    = 7
  notification_topic_arn      = module.alerts.topic_arn

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  security_group_rules = {
    ingress_app = {
      description                  = "Application traffic"
      referenced_security_group_id = module.app.security_group_id
    }
  }
}
```

### Cluster mode Valkey

```hcl
module "redis" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/elasticache-redis?ref=main"

  service     = "bcss"
  project     = "screening"
  environment = "prod"
  name        = "redis-cluster"

  engine                      = "valkey"
  node_type                   = "cache.r7g.large"
  engine_version              = "7.2"
  auth_token                  = "replace-with-a-secret-value"
  cluster_mode_enabled        = true
  num_node_groups             = 2
  replicas_per_node_group     = 1
  automatic_failover_enabled  = true
  multi_az_enabled            = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  security_group_rules = {
    ingress_vpc = {
      description = "VPC traffic"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }
}
```

### Redis OSS compatibility mode

If a caller cannot move to Valkey yet, set `engine = "redis"` explicitly and use a supported
engine version such as `6.x` or `7.x`.

<!-- vale Vale.Spelling = YES -->

## Conventions

* `replication_group_id`, `subnet_group_name`, `parameter_group_name`, and
  `security_group_name` default to the shared context-derived module ID.
* `parameter_group_family` defaults from the selected `engine` and the major
  `engine_version`, for example `7.2` becomes `valkey7` when `engine = "valkey"`.
* `redis_auth_token` and `elasticache_port` are supported as compatibility
  aliases for older callers, but new callers should prefer `auth_token` and
  `port`.
* The module exposes both upstream-style outputs and compatibility aliases for
  the old bespoke module outputs.

## What this module does NOT do

* Create user groups or Redis users. Use the upstream user-group submodule if
  you need Redis ACL management.
* Create a KMS key. Pass an existing key arn through `kms_key_arn`.
* Manage global replication groups or serverless caches. Those are different
  deployment patterns and should be wrapped separately if needed.

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
