# RDS Module

Thin NHS wrapper around [`terraform-aws-modules/rds/aws`](https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest) (v7.2.0).

The module provisions an RDS DB instance together with its subnet group, parameter group, option group, and (optionally) an Enhanced Monitoring IAM role. The caller is responsible for creating a security group (use the dedicated security group module) and passing its ID via `vpc_security_group_ids`.

## Fixed controls

These values are always enforced and cannot be overridden by callers.

| Control | Value | Reason |
|---------|-------|--------|
| `publicly_accessible` | `false` | Databases must never be internet-facing |
| `storage_encrypted` | `true` | Encryption at rest is mandatory |
| `copy_tags_to_snapshot` | `true` | Snapshots must carry the same tags as the instance |
| `auto_minor_version_upgrade` | `false` | Teams keep instances in sync with the production engine version |
| `create_db_subnet_group` | `true` | Subnet group is always managed by this module |

## Usage

### Oracle with a fresh database

```hcl
module "oracle_rds" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws//infrastructure/modules/rds?ref=vX.Y.Z"

  # context
  service     = var.service
  environment = var.environment
  workspace   = terraform.workspace

  # identity
  identifier = "${var.name_prefix}-oracle-${var.environment}-${terraform.workspace}"

  # engine
  engine               = "oracle-ee"
  engine_version       = "19"
  license_model        = "license-included"
  major_engine_version = "19"
  family               = "oracle-ee-19"
  character_set_name   = "AL32UTF8"

  # sizing
  instance_class    = "db.m5.large"
  allocated_storage = 100
  storage_type      = "gp3"

  # database
  db_name  = "MYDB"
  username = var.rds_master_username
  port     = 1521

  # credentials (write-only — not stored in state)
  password_wo         = var.rds_master_password
  password_wo_version = 1

  # networking
  subnet_ids             = data.aws_subnets.private.ids
  vpc_security_group_ids = [module.rds_security_group.security_group_id]

  # options (Oracle S3 integration and timezone)
  options = [
    {
      option_name                    = "S3_INTEGRATION"
      version                        = "1.0"
      port                           = 0
      vpc_security_group_memberships = []
      option_settings                = []
    },
    {
      option_name                    = "Timezone"
      port                           = 0
      vpc_security_group_memberships = []
      option_settings = [
        { name = "TIME_ZONE", value = "Europe/London" }
      ]
    }
  ]

  # parameters
  parameters = [
    { name = "_add_col_optim_enabled", value = "TRUE", apply_method = "immediate" }
  ]

  # availability and backup
  multi_az                = var.environment == "prod" ? true : false
  backup_retention_period = 7
  skip_final_snapshot     = false
  deletion_protection     = var.environment == "prod" ? true : false
}
```

### Restore from snapshot

```hcl
module "oracle_rds" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws//infrastructure/modules/rds?ref=vX.Y.Z"

  # ... (same as above)

  # When restoring from a snapshot, character_set_name must be null
  character_set_name  = null
  snapshot_identifier = "rds:my-db-2024-01-01-06-00"
}
```

### RDS-managed password (no password in Terraform state)

```hcl
module "oracle_rds" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws//infrastructure/modules/rds?ref=vX.Y.Z"

  # ...

  manage_master_user_password = true
  # password_wo is not required when manage_master_user_password = true
}
```

The master password ARN is exposed via the `master_user_secret_arn` output.

## Outputs

| Name | Description |
|------|-------------|
| `instance_address` | Hostname of the RDS instance (without port) |
| `instance_port` | Port number |
| `instance_endpoint` | Connection endpoint in `host:port` format |
| `instance_id` | RDS instance identifier |
| `instance_arn` | ARN of the RDS instance |
| `instance_resource_id` | RDS resource ID (used for IAM authentication) |
| `master_user_secret_arn` | Secrets Manager ARN for the master password (when `manage_master_user_password = true`) |
| `rds_subnet_group` | Object with `.id` and `.arn` for the DB subnet group |
| `db_subnet_group_id` | DB subnet group name/ID |
| `db_parameter_group_id` | DB parameter group ID |
| `db_option_group_id` | DB option group ID |
| `enhanced_monitoring_iam_role_arn` | Enhanced Monitoring IAM role ARN (empty when `monitoring_interval = 0`) |

## Migration from the local bcss `rds` module

When migrating from `../../modules/rds` in the bcss repo to this shared module, note:

1. **Output names** — `instance_endpoint`, `instance_address`, `instance_port`, and `rds_subnet_group` are compatible with the local module. `rds_security_group` is no longer an output — the caller now owns the security group resource.
2. **`snapshot_identifier`** — The local module used `""` as "no snapshot". This module uses `null`. Update the calling stack.
3. **`password_wo`** — The local module accepted `master_password` as a plain variable (stored in state). This module uses `password_wo` (write-only, not persisted in state).
4. **`deletion_protection`** — Defaults to `true` here (defaults to whatever `var.deletion_protection` was in the local module). Add `#checkov:skip=CKV_AWS_293` to the module call in non-production stacks.
5. **`ignore_changes` lifecycle** — The local module ignored `engine`, `engine_version`, `availability_zone`, `db_subnet_group_name`, and `storage_encrypted` on the `aws_db_instance`. These lifecycle rules are inside the community module and cannot be overridden from a wrapper. Raise this as a known limitation in the migration PR.
