# EFS

NHS Screening wrapper around the community
[`terraform-aws-modules/efs/aws`](https://registry.terraform.io/modules/terraform-aws-modules/efs/aws/latest)
module that enforces the platform's baseline controls and consumes
the shared `context.tf` for naming and tagging.

## What this module enforces

|Control|How it is enforced|
|---|---|
|Encryption at rest|KMS encryption is mandatory; `var.kms_key_arn` is required|
|Encryption in transit|TLS is always required; non-secure transport is denied by default|
|Security groups|Mount targets require explicit security groups from the caller; no defaults|
|Destructive operations|Delete operations are denied by default; must be explicitly allowed via policy|
|Tagging|All EFS resources tagged via `module.this.tags`|
|Creation gate|Resource creation gated by `module.this.enabled`|

## Usage

### Minimal EFS with KMS encryption

Simplest setup: multi-AZ, general-purpose file system with default security policies.

```hcl
module "application_efs" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/efs?ref=v1.0.0"

  service     = "bcss"
  project     = "application"
  environment = "production"
  name        = "app-data"

  kms_key_arn = module.efs_kms.key_arn

  mount_targets = {
    "az1" = {
      subnet_id       = aws_subnet.private[0].id
      security_groups = [aws_security_group.efs.id]
    }
    "az2" = {
      subnet_id       = aws_subnet.private[1].id
      security_groups = [aws_security_group.efs.id]
    }
  }
}
```

### Single-AZ EFS for cost savings

Use `availability_zone_name` for cheaper single-AZ deployments (no high availability).

```hcl
module "dev_efs" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/efs?ref=v1.0.0"

  service     = "bcss"
  project     = "development"
  environment = "dev"
  name        = "dev-storage"

  kms_key_arn            = module.efs_kms.key_arn
  availability_zone_name = "eu-west-2a"  # Single AZ deployment

  mount_targets = {
    "primary" = {
      subnet_id       = aws_subnet.private[0].id
      security_groups = [aws_security_group.efs_dev.id]
    }
  }
}
```

### High-performance EFS with provisioned throughput

For workloads requiring consistent throughput (databases, analytics).

```hcl
module "database_efs" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/efs?ref=v1.0.0"

  service     = "bcss"
  project     = "database"
  environment = "production"
  name        = "db-storage"

  kms_key_arn                 = module.efs_kms.key_arn
  performance_mode            = "maxIO"
  throughput_mode             = "provisioned"
  provisioned_throughput_in_mibps = 100

  mount_targets = {
    "az1" = {
      subnet_id       = aws_subnet.private[0].id
      security_groups = [aws_security_group.efs_db.id]
    }
    "az2" = {
      subnet_id       = aws_subnet.private[1].id
      security_groups = [aws_security_group.efs_db.id]
    }
  }
}
```

### EFS with lifecycle policies and automated backup

Transition older data to infrequent access storage class automatically.

```hcl
module "archive_efs" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/efs?ref=v1.0.0"

  service     = "bcss"
  project     = "archive"
  environment = "production"
  name        = "archive-storage"

  kms_key_arn = module.efs_kms.key_arn

  # Transition data to infrequent access after 30 days of inactivity
  lifecycle_policy = {
    transition_to_ia                    = "AFTER_30_DAYS"
    transition_to_primary_storage_class = "AFTER_1_DAY"  # Restore to standard if accessed
  }

  protection = {
    enable_backup = true  # Enable automated backup via AWS Backup
  }

  mount_targets = {
    "az1" = {
      subnet_id       = aws_subnet.private[0].id
      security_groups = [aws_security_group.efs.id]
    }
  }
}
```

### EFS with Access Points for application isolation

Use Access Points to enforce POSIX user identity and root directory isolation for multi-tenant workloads.

```hcl
module "multitenant_efs" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/efs?ref=v1.0.0"

  service     = "bcss"
  project     = "multitenant"
  environment = "production"
  name        = "shared-storage"

  kms_key_arn = module.efs_kms.key_arn

  # Each application gets its own access point with enforced user identity
  access_points = {
    "web-app" = {
      enforced_user_id  = "1001"
      root_directory_path = "/web-app"
      permissions_mode  = "700"
    }
    "api-service" = {
      enforced_user_id  = "1002"
      root_directory_path = "/api-service"
      permissions_mode  = "700"
    }
    "batch-job" = {
      enforced_user_id  = "1003"
      root_directory_path = "/batch"
      permissions_mode  = "755"
    }
  }

  mount_targets = {
    "az1" = {
      subnet_id       = aws_subnet.private[0].id
      security_groups = [aws_security_group.efs.id]
    }
    "az2" = {
      subnet_id       = aws_subnet.private[1].id
      security_groups = [aws_security_group.efs.id]
    }
  }
}
```

### EFS with cross-region replication for disaster recovery

Replicate to secondary region for business continuity.

```hcl
module "replicated_efs" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/efs?ref=v1.0.0"

  service     = "bcss"
  project     = "critical-data"
  environment = "production"
  name        = "replicated-storage"

  kms_key_arn = module.efs_kms.key_arn

  # Enable replication to eu-west-1
  replication_configuration = {
    destination = "eu-west-1"
  }

  protection = {
    replication_overwrite = "DISABLED"  # Prevent accidental overwrites
  }

  mount_targets = {
    "az1" = {
      subnet_id       = aws_subnet.private[0].id
      security_groups = [aws_security_group.efs.id]
    }
    "az2" = {
      subnet_id       = aws_subnet.private[1].id
      security_groups = [aws_security_group.efs.id]
    }
  }
}
```

### Secure EFS with TLS 1.2 enforcement and IP restrictions

Enforce strong TLS version and restrict access to specific network ranges.

```hcl
module "secure_efs" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/efs?ref=v1.0.0"

  service     = "bcss"
  project     = "secure-data"
  environment = "production"
  name        = "secure-storage"

  kms_key_arn = module.efs_kms.key_arn

  # Enforce TLS 1.2 minimum and restrict to VPC CIDR
  require_tls_version = "1.2"
  allowed_source_ips  = ["10.0.0.0/8"]  # Your VPC CIDR

  # Prevent accidental deletion (must explicitly allow in custom policy)
  deny_destructive_operations = true

  mount_targets = {
    "az1" = {
      subnet_id       = aws_subnet.private[0].id
      security_groups = [aws_security_group.efs_secure.id]
    }
    "az2" = {
      subnet_id       = aws_subnet.private[1].id
      security_groups = [aws_security_group.efs_secure.id]
    }
  }
}
```

### EFS with custom IAM policy for admin-only deletions

Demonstrate how to allow destructive operations only for specific IAM roles.

```hcl
module "efs_with_admin_policy" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/efs?ref=v1.0.0"

  service     = "bcss"
  project     = "production-data"
  environment = "production"
  name        = "protected-storage"

  kms_key_arn = module.efs_kms.key_arn

  # Enable all default security policies
  deny_unsecure_transport     = true
  require_tls_version         = "1.2"
  deny_destructive_operations = true

  # Custom policy: allow deletion only by infrastructure-admin role
  file_system_policy = jsonencode({
    Statement = [
      {
        Sid    = "AllowInfraAdminDelete"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/infrastructure-admin"
        }
        Action = [
          "elasticfilesystem:DeleteFileSystem",
          "elasticfilesystem:DeleteAccessPoint"
        ]
        Resource = "*"
      }
    ]
  })

  mount_targets = {
    "az1" = {
      subnet_id       = aws_subnet.private[0].id
      security_groups = [aws_security_group.efs.id]
    }
    "az2" = {
      subnet_id       = aws_subnet.private[1].id
      security_groups = [aws_security_group.efs.id]
    }
  }
}
```

### Comprehensive production setup with all features

Multi-AZ, high-performance, encrypted, replicated, with access points and security policies.

```hcl
module "production_efs" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/efs?ref=v1.0.0"

  service     = "bcss"
  project     = "platform"
  environment = "production"
  name        = "platform-data"

  kms_key_arn = module.efs_kms.key_arn

  # Performance: provisioned throughput for predictable performance
  performance_mode                = "generalPurpose"
  throughput_mode                 = "provisioned"
  provisioned_throughput_in_mibps = 50

  # Lifecycle: optimize storage costs over time
  lifecycle_policy = {
    transition_to_ia = "AFTER_60_DAYS"
  }

  # Protection: backup and prevent accidental overwrites
  protection = {
    enable_backup           = true
    replication_overwrite   = "DISABLED"
  }

  # Replication: disaster recovery to secondary region
  replication_configuration = {
    destination = "eu-west-1"
  }

  # Security: enforce TLS 1.2 and restrict to VPC
  require_tls_version = "1.2"
  allowed_source_ips  = ["10.0.0.0/8"]

  # Access control: application isolation via access points
  access_points = {
    "api" = {
      enforced_user_id    = "1000"
      root_directory_path = "/api"
      permissions_mode    = "750"
    }
    "database" = {
      enforced_user_id    = "1001"
      root_directory_path = "/db"
      permissions_mode    = "700"
    }
  }

  # Multi-AZ mount targets for high availability
  mount_targets = {
    "az1" = {
      subnet_id       = aws_subnet.private[0].id
      security_groups = [aws_security_group.efs.id]
    }
    "az2" = {
      subnet_id       = aws_subnet.private[1].id
      security_groups = [aws_security_group.efs.id]
    }
    "az3" = {
      subnet_id       = aws_subnet.private[2].id
      security_groups = [aws_security_group.efs.id]
    }
  }
}
```

## Security Group Requirements

EFS communication uses NFS (NFSv4.1), not SSH or HTTP. Your security groups must allow:

```hcl
# Allow NFS protocol
resource "aws_security_group_rule" "efs_nfs" {
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]  # Your application's CIDR
  security_group_id = aws_security_group.efs.id
}

# Allow NFS port mapper (optional, only if needed)
resource "aws_security_group_rule" "efs_portmapper" {
  type              = "ingress"
  from_port         = 111
  to_port           = 111
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = aws_security_group.efs.id
}
```

## Conventions

- **Encryption:** KMS encryption is mandatory. Callers must provide a KMS key ARN via `var.kms_key_arn`. AWS managed keys are not used.
- **Security groups:** Callers must provide security groups for each mount target. See [Security Group Requirements](#security-group-requirements) above.
- **Mount targets:** Each mount target requires a subnet and security groups. For high availability, provision one mount target per AZ.
- **Custom naming:** By default, the EFS name is derived from `module.this.id`. Override with `var.custom_name` if needed.
- **Access Points:** When using access points, applications must use the access point ARN (not the file system ARN) in their NFS mount.

## File System Policy (Resource-Based Access Control)

This module automatically adds security-focused policy statements to the EFS file system policy. These are enabled by default and can be controlled or disabled as needed:

### Default Security Statements

| Statement | Default | Purpose |
| --- | --- | --- |
| `DenyUnsecureTransport` | Enabled | Denies all EFS operations over non-TLS connections (`aws:SecureTransport = false`) |
| `DenyOldTLSVersion` | Disabled | Denies operations using TLS versions older than specified via `var.require_tls_version` |
| `DenyUnauthorizedSourceIPs` | Disabled | Restricts EFS access to specific CIDR blocks via `var.allowed_source_ips` |
| `DenyDestructiveOperations` | Enabled | Denies `DeleteFileSystem`, `DeleteAccessPoint`, etc. by default (callers must explicitly allow via custom policy) |

### Controlling Policy Statements

```hcl
# Require TLS 1.2 or higher
require_tls_version = "1.2"

# Restrict to specific VPC CIDR blocks
allowed_source_ips = ["10.0.0.0/8", "172.16.0.0/12"]

# Disable automatic deny of destructive operations (not recommended)
deny_destructive_operations = false

# Disable all automatic policy statements
deny_unsecure_transport = false
require_tls_version     = null
allowed_source_ips      = []
```

### Custom Policy Statements

Caller-provided policy statements (via `var.file_system_policy`) are merged with the default security statements. To allow destructive operations:

```hcl
file_system_policy = jsonencode({
  Statement = [
    {
      Sid    = "AllowDeleteForAdmins"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::ACCOUNT:role/AdminRole"
      }
      Action   = ["elasticfilesystem:DeleteFileSystem"]
      Resource = "*"
    }
  ]
})
```

## Validation

The following cross-variable constraints are enforced in `validations.tf`:

- **Provisioned throughput mode requires throughput setting:** If `throughput_mode = "provisioned"`, `provisioned_throughput_in_mibps` must be set.
- **Replication requires mount targets:** If `replication_configuration` is set, at least one mount target must be configured.
- **Access points require mount targets:** If `access_points` is set, at least one mount target must be configured.

## Outputs

- `efs_id` — The EFS file system ID (e.g., `fs-12345678`)
- `efs_arn` — The ARN of the file system
- `efs_dns_name` — The DNS name for NFS mounting (e.g., `fs-12345678.efs.eu-west-2.amazonaws.com`)
- `efs_size_in_bytes` — Latest metered size of the file system
- `kms_key_arn` — The KMS key ARN used for encryption
- `mount_targets` — Map of mount target IDs and subnet associations
- `access_points` — Map of access point IDs and ARNs (if configured)
- `replication_configuration` — The destination file system ID (if replication enabled)
- `file_system_policy_id` — The policy ID (if custom policy attached)

## What this module does NOT do

- Create KMS keys. Use the `kms` module and pass the key ARN via `var.kms_key_arn`.
- Create security groups. Callers must provide and manage security groups for mount targets.
- Create subnets. Callers must provide target subnets for mount targets.
- Create DNS records. Use Route 53 or your DNS provider to create records pointing to `efs_dns_name` if needed.
- Enable data sync or backup scheduling. Use AWS DataSync or AWS Backup to configure automated workflows.
- Configure VPC endpoints for EFS. The module uses standard EFS DNS; VPC endpoints are optional and managed separately.

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.28 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.55.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_efs"></a> [efs](#module\_efs) | terraform-aws-modules/efs/aws | 2.2.0 |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_efs_access_point.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_access_point) | resource |
| [aws_efs_file_system_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system_policy) | resource |
| [terraform_data.validations](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_access_points"></a> [access\_points](#input\_access\_points) | Map of EFS Access Point configurations for application-level mount points.<br/>Access Points enforce POSIX user identities and enforce a file system root.<br/>Leave as {} to create no access points.<br/><br/>Example:<br/>  access\_points = {<br/>    "app-root" = {<br/>      enforced\_user\_id = "1000"<br/>      root\_directory\_path = "/app"<br/>      permissions\_mode = "755"<br/>    }<br/>    "db-root" = {<br/>      enforced\_user\_id = "1001"<br/>      root\_directory\_path = "/data"<br/>      permissions\_mode = "700"<br/>    }<br/>  } | `any` | `{}` | no |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_allowed_source_ips"></a> [allowed\_source\_ips](#input\_allowed\_source\_ips) | List of CIDR blocks allowed to access the EFS. When set, a Deny statement restricts access to these IPs. Leave as [] to skip IP-based restrictions. | `list(string)` | `[]` | no |
| <a name="input_application_role"></a> [application\_role](#input\_application\_role) | The role the application is performing | `string` | `"General"` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_availability_zone_name"></a> [availability\_zone\_name](#input\_availability\_zone\_name) | AWS Availability Zone for One Zone storage class. When set, the file system uses single-AZ storage for lower cost. Leave null for multi-AZ. | `string` | `null` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "project": null,<br/>  "regex_replace_chars": null,<br/>  "region": null,<br/>  "service": null,<br/>  "stack": null,<br/>  "tags": {},<br/>  "terraform_source": null,<br/>  "workspace": null<br/>}</pre> | no |
| <a name="input_creation_token"></a> [creation\_token](#input\_creation\_token) | A unique name (max 64 chars) used as reference when creating the file system. Enables idempotent creation. When null, Terraform generates a token. | `string` | `null` | no |
| <a name="input_custom_name"></a> [custom\_name](#input\_custom\_name) | Optional explicit EFS name. When null, the name is derived from module.this.id. | `string` | `null` | no |
| <a name="input_data_classification"></a> [data\_classification](#input\_data\_classification) | Used to identify the data classification of the resource, e.g 1-5 | `string` | `"n/a"` | no |
| <a name="input_data_type"></a> [data\_type](#input\_data\_type) | The tag data\_type | `string` | `"None"` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_deny_destructive_operations"></a> [deny\_destructive\_operations](#input\_deny\_destructive\_operations) | Whether to add a Deny statement for destructive operations (DeleteFileSystem, DeleteAccessPoint) by default. Callers must explicitly allow these via var.file\_system\_policy. Recommended: true. | `bool` | `true` | no |
| <a name="input_deny_unsecure_transport"></a> [deny\_unsecure\_transport](#input\_deny\_unsecure\_transport) | Whether to automatically add a Deny statement for non-TLS (unsecure) transport to the file system policy. Recommended: true. | `bool` | `true` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>    format = string<br/>    labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_file_system_policy"></a> [file\_system\_policy](#input\_file\_system\_policy) | Optional IAM policy document (as JSON string) to attach to the file system.<br/>Controls who can perform what actions on the EFS resource.<br/>When null, no resource-based policy is attached.<br/><br/>Security baseline: Callers should consider denying nonsecure (non-TLS) transport:<br/>  - aws:SecureTransport condition set to false | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of the KMS key used for encryption at rest. Encryption is mandatory; this variable is required. | `string` | n/a | yes |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_lifecycle_policy"></a> [lifecycle\_policy](#input\_lifecycle\_policy) | Optional lifecycle policy for automatic transition to other storage classes.<br/>Leave as {} to disable. Example:<br/>  lifecycle\_policy = {<br/>    transition\_to\_ia                  = "AFTER\_30\_DAYS"<br/>    transition\_to\_primary\_storage\_class = "AFTER\_1\_DAY"<br/>  } | `any` | `{}` | no |
| <a name="input_mount_targets"></a> [mount\_targets](#input\_mount\_targets) | Map of mount target configurations. Each mount target must specify:<br/>- subnet\_id: Subnet where the mount target resides (required)<br/>- security\_groups: List of security group IDs (required; caller must enforce ingress rules for NFSv4.1)<br/>- ip\_address: (optional) Static IP address for the mount target<br/>- ip\_address\_type: (optional) IP address type (ipv4 or ipv6)<br/>- ipv6\_address: (optional) IPv6 address for the mount target<br/><br/>Example:<br/>  mount\_targets = {<br/>    "az1" = {<br/>      subnet\_id       = "subnet-12345"<br/>      security\_groups = ["sg-12345"]<br/>    }<br/>    "az2" = {<br/>      subnet\_id       = "subnet-67890"<br/>      security\_groups = ["sg-67890"]<br/>      ip\_address      = "10.0.1.100"<br/>    }<br/>  } | `any` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_on_off_pattern"></a> [on\_off\_pattern](#input\_on\_off\_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_performance_mode"></a> [performance\_mode](#input\_performance\_mode) | The file system performance mode. Either 'generalPurpose' or 'maxIO'. | `string` | `"generalPurpose"` | no |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_protection"></a> [protection](#input\_protection) | Configuration for replication protection and backup policy.<br/><br/>Defaults:<br/>- enable\_backup: true (enables automated backups via AWS Backup)<br/>- replication\_overwrite: DISABLED (prevents accidental overwrites of replicas during replication) | <pre>object({<br/>    enable_backup         = optional(bool, true)<br/>    replication_overwrite = optional(string, "DISABLED")<br/>  })</pre> | `{}` | no |
| <a name="input_provisioned_throughput_in_mibps"></a> [provisioned\_throughput\_in\_mibps](#input\_provisioned\_throughput\_in\_mibps) | The throughput to provision for the file system in MiB/s. Required when throughput\_mode is 'provisioned'. Range: 1–1024. | `number` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_replication_configuration"></a> [replication\_configuration](#input\_replication\_configuration) | Replication configuration for cross-region disaster recovery.<br/>Leave as {} to disable replication.<br/><br/>Example:<br/>  replication\_configuration = {<br/>    destination = "eu-west-1"<br/>  } | `any` | `{}` | no |
| <a name="input_require_tls_version"></a> [require\_tls\_version](#input\_require\_tls\_version) | Minimum TLS version to enforce via file system policy (e.g., '1.2', '1.3'). When set, a Deny statement is added for lower versions. Leave null to skip TLS version enforcement. | `string` | `null` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to the caller module path when not set. | `string` | `null` | no |
| <a name="input_throughput_mode"></a> [throughput\_mode](#input\_throughput\_mode) | Throughput mode for the file system. Either 'bursting' (default) or 'provisioned'. | `string` | `"bursting"` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_access_points"></a> [access\_points](#output\_access\_points) | Map of EFS Access Point IDs and their ARNs, keyed by the input map keys. |
| <a name="output_efs_arn"></a> [efs\_arn](#output\_efs\_arn) | The Amazon Resource Name (ARN) of the EFS file system. |
| <a name="output_efs_dns_name"></a> [efs\_dns\_name](#output\_efs\_dns\_name) | The DNS name of the EFS file system. |
| <a name="output_efs_encrypted"></a> [efs\_encrypted](#output\_efs\_encrypted) | Always true; encryption is enforced by this module. |
| <a name="output_efs_id"></a> [efs\_id](#output\_efs\_id) | The ID of the EFS file system. |
| <a name="output_efs_size_in_bytes"></a> [efs\_size\_in\_bytes](#output\_efs\_size\_in\_bytes) | The latest metered size of the EFS in bytes. |
| <a name="output_file_system_policy_id"></a> [file\_system\_policy\_id](#output\_file\_system\_policy\_id) | The file system policy ID (if policy was attached). |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | The ARN of the KMS key used for encryption. |
| <a name="output_mount_targets"></a> [mount\_targets](#output\_mount\_targets) | Map of mount target IDs and their associated subnet IDs. |
| <a name="output_replication_configuration"></a> [replication\_configuration](#output\_replication\_configuration) | The replication configuration of the EFS file system, if enabled. |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
