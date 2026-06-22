# Network Firewall

NHS Screening wrapper around the community [`terraform-aws-modules/network-firewall/aws`](https://registry.terraform.io/modules/terraform-aws-modules/network-firewall/aws/latest) module that enforces the platform's baseline security controls.

Deploys an AWS Network Firewall into dedicated firewall subnets created by the VPC module, with flexible logging, KMS encryption, and configurable stateful/stateless rule groups.

## What this module enforces

|Control|Status|Implementation|
|---|---|---|
|Deletion protection|✅ **Enforced**|Enabled by default (`delete_protection = true`); opt-out requires explicit override|
|Subnet change protection|✅ **Enforced**|Enabled by default (`subnet_change_protection = true`); guards against accidental subnet modifications|
|Logging disabled by default|✅ **Enforced**|Logging is opt-in via `create_logging_configuration = true`; prevents unintended log ingestion costs|
|Encryption at rest (KMS)|⚠️ **Optional**|AWS-managed encryption by default; customer-managed KMS via `kms_key_arn` parameter (production recommended)|
|Encryption in transit (TLS)|⚠️ **AWS default**|AWS enforces TLS for firewall API and logging destinations; module does not add validation|
|Least-privilege IAM|⚠️ **Upstream module**|The underlying `terraform-aws-modules/network-firewall/aws` follows AWS best practices; module does not restrict caller's rule definitions|
|Audit trail|⚠️ **Caller-configured**|Platform CloudTrail logs API calls; firewall logs (FLOW/ALERT/TLS) require explicit `logging` configuration|

## Usage

### Minimal

```hcl
module "network_firewall" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/network-firewall?ref=v2.1.0"

  service             = "bcss"
  project             = "bcss"
  environment         = "dev"
  stack               = "shared-resources"
  name                = "nwfw"

  vpc_id              = module.vpc.vpc_id
  firewall_subnet_ids = module.vpc.firewall_subnet_ids
}
```

### Production-style (with encryption and logging best practices)

```hcl
# Production deployment with customer-managed KMS, comprehensive logging,
# and protection against accidental modifications.

module "network_firewall" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/network-firewall?ref=v2.1.0"

  service             = "bcss"
  project             = "bcss"
  environment         = "prod"
  stack               = "shared-resources"
  name                = "nwfw"

  vpc_id              = module.vpc.vpc_id
  firewall_subnet_ids = module.vpc.firewall_subnet_ids

  # ========================================================================
  # Encryption at rest — customer-managed KMS (recommended for prod)
  # ========================================================================
  kms_key_arn                = module.nwfw_kms.key_arn
  alert_log_group_kms_key_id = module.nwfw_kms.key_arn

  # ========================================================================
  # Logging — comprehensive multi-destination setup
  # ========================================================================
  # FLOW logs → S3 (long-term archive, analysis)
  # ALERT logs → CloudWatch (real-time alerting, metric filters)
  # TLS logs → S3 (compliance, SSL/TLS inspection audit trail)
  create_logging_configuration = true
  logging = {
    flow_s3 = {
      log_type             = "FLOW"
      log_destination_type = "S3"
      log_destination      = { bucketName = module.logs_bucket.id, prefix = "nwfw/flow-logs" }
      enabled              = true
    }
    alert_cloudwatch = {
      log_type             = "ALERT"
      log_destination_type = "CloudWatchLogs"
      log_destination      = { logGroup = module.network_firewall.alert_log_group_name }
      enabled              = true
    }
    tls_s3 = {
      log_type             = "TLS"
      log_destination_type = "S3"
      log_destination      = { bucketName = module.logs_bucket.id, prefix = "nwfw/tls-logs" }
      enabled              = true
    }
  }

  # Managed CloudWatch log group with retention and encryption
  create_alert_log_group            = true
  alert_log_group_retention_in_days = 90  # Compliance requirement

  # ========================================================================
  # Protection against accidental changes
  # ========================================================================
  delete_protection                 = true   # Enforced by module default
  subnet_change_protection          = true   # Enforced by module default
  firewall_policy_change_protection = true   # Recommended for prod

  # ========================================================================
  # Threat detection and metrics
  # ========================================================================
  enabled_analysis_types = ["TLS_SNI", "HTTP_HOST"]

  tags = merge(
    module.this.tags,
    {
      Compliance  = "NHS-Baseline"
      CostCenter  = "Network-Operations"
      Environment = "Production"
    }
  )
}

# KMS key for encrypting firewall and logs
module "nwfw_kms" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/kms?ref=v2.1.0"

  service     = var.service
  project     = var.project
  environment = var.environment
  stack       = var.stack
  name        = "nwfw"

  description = "KMS key for Network Firewall encryption (firewall, policy, CloudWatch logs)"
  key_usage   = "ENCRYPT_DECRYPT"

  # Allow firewall and logs services to use the key
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowNetworkFirewallEncryption"
        Effect = "Allow"
        Principal = {
          Service = "network-firewall.amazonaws.com"
        }
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogsEncryption"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:CreateGrant", "kms:DescribeKey"]
        Resource = "*"
      }
    ]
  })

  tags = module.this.tags
}

# S3 bucket for firewall logs with versioning and encryption
module "logs_bucket" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/s3-bucket?ref=v2.1.0"

  service     = var.service
  project     = var.project
  environment = var.environment
  stack       = var.stack
  name        = "nwfw-logs"

  versioning_enabled       = true
  server_side_encryption   = "aws:kms"
  kms_master_key_id        = module.nwfw_kms.key_id
  block_public_access      = true
  enforce_ssl              = true
  lifecycle_rule_id        = "archive-old-logs"
  lifecycle_rule_prefix    = "nwfw/"
  lifecycle_transition_days = 90

  tags = module.this.tags
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
```

### Advanced (multi-AZ with custom rule groups)

```hcl
module "network_firewall" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/network-firewall?ref=v2.1.0"

  service             = "bcss"
  project             = "bcss"
  environment         = "prod"
  stack               = "shared-resources"
  name                = "nwfw"

  # Multi-AZ deployment — provide one subnet per AZ
  vpc_id              = module.vpc.vpc_id
  firewall_subnet_ids = module.vpc.firewall_subnet_ids  # e.g., [subnet-az1, subnet-az2, subnet-az3]

  # Encryption
  kms_key_arn                = module.nwfw_kms.key_arn
  alert_log_group_kms_key_id = module.nwfw_kms.key_arn

  # Logging to all three destinations
  create_logging_configuration = true
  logging = {
    flow_s3 = {
      log_type             = "FLOW"
      log_destination_type = "S3"
      log_destination      = { bucketName = module.logs_bucket.id, prefix = "nwfw/flow" }
    }
    alert_s3 = {
      log_type             = "ALERT"
      log_destination_type = "S3"
      log_destination      = { bucketName = module.logs_bucket.id, prefix = "nwfw/alerts" }
    }
    tls_firehose = {
      log_type             = "TLS"
      log_destination_type = "KinesisDataFirehose"
      log_destination      = { deliveryStream = "nwfw-tls-stream" }
    }
  }

  create_alert_log_group            = true
  alert_log_group_retention_in_days = 90

  # Custom rule groups for domain blocking and threat inspection
  rule_groups = {
    deny_known_malware_domains = {
      description = "Block known-bad domains via TLS SNI and HTTP Host"
      type        = "STATEFUL"
      capacity    = 100
      priority    = 1
      rule_group = {
        stateful_rule_options = { rule_order = "STRICT_ORDER" }
        rules_source = {
          rules_source_list = {
            generated_rules_type = "DENYLIST"
            target_types         = ["TLS_SNI", "HTTP_HOST"]
            targets              = ["badsite.example.com", ".malware.net"]
          }
        }
      }
    }
    inspect_ssl = {
      description = "Enable SSL/TLS inspection on suspicious traffic"
      type        = "STATEFUL"
      capacity    = 50
      priority    = 5
      rules       = "alert tls any any -> any any (msg:\"SSL inspection enabled\"; ssl_version:!tls1.3; sid:100001;)"
      rule_group = {
        stateful_rule_options = { rule_order = "STRICT_ORDER" }
      }
    }
  }

  policy_stateful_default_actions = ["aws:drop_strict"]
  policy_stateful_engine_options = {
    rule_order = "STRICT_ORDER"
    stream_exception_policy = "DROP"
  }

  # Stateless default actions: forward established connections
  policy_stateless_default_actions = ["aws:forward_to_sfe"]
  policy_stateless_fragment_default_actions = ["aws:forward_to_sfe"]

  delete_protection                 = true
  subnet_change_protection          = true
  firewall_policy_change_protection = true

  enabled_analysis_types = ["TLS_SNI", "HTTP_HOST"]

  tags = merge(
    module.this.tags,
    {
      Compliance = "NHS-Baseline"
      Monitoring = "Advanced"
    }
  )
}
```

## Conventions

**Naming and tagging:** All resources (firewall, policy, rule groups, log groups) are named and tagged via `module.this`. Callers should provide at least `service`, `project`, `environment`, `stack`, and `name` to get consistent, platform-compliant names.

**Rule group priority:** Rule groups are processed in priority order (lowest first). When creating multiple rule groups via `rule_groups`, set explicit `priority` values to control evaluation order. The `policy_stateful_default_actions` (e.g. `["aws:drop_strict"]`) apply to packets that match no rules.

**Logging configuration:** By default, logging is disabled. To enable, set `create_logging_configuration = true` and provide a `logging` map with destination configs. AWS allows at most one log destination per log type (FLOW, ALERT, TLS). Each destination must specify `log_type`, `log_destination_type` (S3, CloudWatchLogs, or KinesisDataFirehose), and log_destination-specific keys (see `variables.tf` for details).

**CloudWatch log groups:** The module can optionally create and manage a CloudWatch log group for ALERT logs (set `create_alert_log_group = true`). The log group name is `/aws/network-firewall/{firewall_id}` and is exposed via `alert_log_group_name` output for use in the `logging` variable.

**External policies:** By default, this module creates a firewall policy inline. To use an externally managed policy (e.g. shared via Resource Access Manager), set `create_policy = false` and provide `firewall_policy_arn`.

## What this module does NOT do

- **Does NOT create VPC or subnets.** Callers must provide firewall subnet IDs created by the VPC module.
- **Does NOT create S3 buckets, Kinesis Firehose streams, or KMS keys.** Callers must create and pass ARNs/names as needed.
- **Does NOT enforce a fixed set of firewall rules.** Rules are caller-supplied and must be appropriate for the platform.
- **Does NOT manage rule group lifecycle after creation.** Once created, rule groups are the caller's responsibility (no auto-rollback, no versioning).
- **Does NOT create or manage Route tables or routing to the firewall.** Callers handle VPC routing configuration.
- **Does NOT manage alerts or metrics beyond enabling optional logging.** CloudWatch monitoring/alarming is caller-configured.

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.28, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.51.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_network_firewall"></a> [network\_firewall](#module\_network\_firewall) | terraform-aws-modules/network-firewall/aws | 2.1.0 |
| <a name="module_rule_group"></a> [rule\_group](#module\_rule\_group) | terraform-aws-modules/network-firewall/aws//modules/rule-group | 2.1.0 |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_log_group.alert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_alert_log_group_kms_key_id"></a> [alert\_log\_group\_kms\_key\_id](#input\_alert\_log\_group\_kms\_key\_id) | ARN of a KMS key to encrypt the managed CloudWatch alert log group. Leave null for no encryption. | `string` | `null` | no |
| <a name="input_alert_log_group_retention_in_days"></a> [alert\_log\_group\_retention\_in\_days](#input\_alert\_log\_group\_retention\_in\_days) | Number of days to retain logs in the managed alert log group. | `number` | `365` | no |
| <a name="input_application_role"></a> [application\_role](#input\_application\_role) | The role the application is performing | `string` | `"General"` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "project": null,<br/>  "regex_replace_chars": null,<br/>  "region": null,<br/>  "service": null,<br/>  "stack": null,<br/>  "tags": {},<br/>  "terraform_source": null,<br/>  "workspace": null<br/>}</pre> | no |
| <a name="input_create_alert_log_group"></a> [create\_alert\_log\_group](#input\_create\_alert\_log\_group) | Create a managed CloudWatch Log Group for ALERT logs. The log group name is exposed via the alert\_log\_group\_name output. | `bool` | `false` | no |
| <a name="input_create_logging_configuration"></a> [create\_logging\_configuration](#input\_create\_logging\_configuration) | Master toggle for logging configuration. Must be plan-time-known. When true, the `logging` map is used to build destination configs. | `bool` | `false` | no |
| <a name="input_create_policy"></a> [create\_policy](#input\_create\_policy) | Create the firewall policy. Set to false and supply firewall\_policy\_arn to use an externally managed policy. | `bool` | `true` | no |
| <a name="input_data_classification"></a> [data\_classification](#input\_data\_classification) | Used to identify the data classification of the resource, e.g 1-5 | `string` | `"n/a"` | no |
| <a name="input_data_type"></a> [data\_type](#input\_data\_type) | The tag data\_type | `string` | `"None"` | no |
| <a name="input_delete_protection"></a> [delete\_protection](#input\_delete\_protection) | Prevent accidental deletion of the firewall. | `bool` | `true` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | A friendly description of the firewall. | `string` | `""` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>    format = string<br/>    labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_enabled_analysis_types"></a> [enabled\_analysis\_types](#input\_enabled\_analysis\_types) | Types for which to collect analysis metrics. Valid values: TLS\_SNI, HTTP\_HOST. | `list(string)` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_firewall_policy_arn"></a> [firewall\_policy\_arn](#input\_firewall\_policy\_arn) | ARN of an externally managed firewall policy. Only used when create\_policy is false. | `string` | `""` | no |
| <a name="input_firewall_policy_change_protection"></a> [firewall\_policy\_change\_protection](#input\_firewall\_policy\_change\_protection) | Prevent changes to the associated firewall policy. | `bool` | `false` | no |
| <a name="input_firewall_subnet_ids"></a> [firewall\_subnet\_ids](#input\_firewall\_subnet\_ids) | List of firewall subnet IDs (one per AZ) from the VPC module. | `list(string)` | n/a | yes |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of a KMS key to encrypt the firewall and its policy. Leave null for AWS-managed encryption. | `string` | `null` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_logging"></a> [logging](#input\_logging) | Map of logging destinations. Each key creates one log\_destination\_config block. See variable comments for shape and examples. | <pre>map(object({<br/>    enabled              = optional(bool, true)<br/>    log_type             = string      # FLOW, ALERT, or TLS<br/>    log_destination_type = string      # S3, CloudWatchLogs, or KinesisDataFirehose<br/>    log_destination      = map(string) # destination-specific keys (see comments above)<br/>  }))</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_on_off_pattern"></a> [on\_off\_pattern](#input\_on\_off\_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_policy_stateful_default_actions"></a> [policy\_stateful\_default\_actions](#input\_policy\_stateful\_default\_actions) | Actions for packets that match no stateful rules. Only valid with STRICT\_ORDER rule order. | `list(string)` | `null` | no |
| <a name="input_policy_stateful_engine_options"></a> [policy\_stateful\_engine\_options](#input\_policy\_stateful\_engine\_options) | Stateful engine options (rule\_order, stream\_exception\_policy, flow\_timeouts). | <pre>object({<br/>    flow_timeouts = optional(object({<br/>      tcp_idle_timeout_seconds = optional(number)<br/>    }))<br/>    rule_order              = optional(string)<br/>    stream_exception_policy = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_policy_stateful_rule_group_reference"></a> [policy\_stateful\_rule\_group\_reference](#input\_policy\_stateful\_rule\_group\_reference) | Map of stateful rule group references for the policy. | <pre>map(object({<br/>    deep_threat_inspection = optional(bool)<br/>    override = optional(object({<br/>      action = optional(string)<br/>    }))<br/>    priority     = optional(number)<br/>    resource_arn = string<br/>  }))</pre> | `null` | no |
| <a name="input_policy_stateless_custom_action"></a> [policy\_stateless\_custom\_action](#input\_policy\_stateless\_custom\_action) | Custom action definitions for the firewall policy's stateless default actions. | <pre>map(object({<br/>    action_definition = object({<br/>      publish_metric_action = optional(object({<br/>        dimension = optional(string)<br/>      }))<br/>    })<br/>    action_name = string<br/>  }))</pre> | `null` | no |
| <a name="input_policy_stateless_default_actions"></a> [policy\_stateless\_default\_actions](#input\_policy\_stateless\_default\_actions) | Actions for packets that match no stateless rules. Default forwards all traffic to the stateful engine. | `list(string)` | <pre>[<br/>  "aws:forward_to_sfe"<br/>]</pre> | no |
| <a name="input_policy_stateless_fragment_default_actions"></a> [policy\_stateless\_fragment\_default\_actions](#input\_policy\_stateless\_fragment\_default\_actions) | Actions for fragmented packets that match no stateless rules. | `list(string)` | <pre>[<br/>  "aws:forward_to_sfe"<br/>]</pre> | no |
| <a name="input_policy_stateless_rule_group_reference"></a> [policy\_stateless\_rule\_group\_reference](#input\_policy\_stateless\_rule\_group\_reference) | Map of stateless rule group references for the policy. | <pre>map(object({<br/>    priority     = number<br/>    resource_arn = string<br/>  }))</pre> | `null` | no |
| <a name="input_policy_variables"></a> [policy\_variables](#input\_policy\_variables) | Variables to override default Suricata settings in the firewall policy. | <pre>object({<br/>    rule_variables = list(object({<br/>      ip_set = optional(object({<br/>        definition = list(string)<br/>      }))<br/>      key = string<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_rule_groups"></a> [rule\_groups](#input\_rule\_groups) | Map of rule group definitions to create and attach to the firewall policy. See variable comments for shape and examples. | <pre>map(object({<br/>    description = optional(string)<br/>    type        = optional(string, "STATEFUL")<br/>    capacity    = optional(number, 100)<br/>    priority    = optional(number)<br/>    rules       = optional(string)<br/>    rule_group  = optional(any)<br/>  }))</pre> | `{}` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_subnet_change_protection"></a> [subnet\_change\_protection](#input\_subnet\_change\_protection) | Prevent changes to the associated subnets. | `bool` | `true` | no |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to this module path. | `string` | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC where the Network Firewall will be deployed. | `string` | n/a | yes |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_alert_log_group_arn"></a> [alert\_log\_group\_arn](#output\_alert\_log\_group\_arn) | The ARN of the CloudWatch Log Group for ALERT logs. |
| <a name="output_alert_log_group_name"></a> [alert\_log\_group\_name](#output\_alert\_log\_group\_name) | The name of the CloudWatch Log Group for ALERT logs. |
| <a name="output_firewall_arn"></a> [firewall\_arn](#output\_firewall\_arn) | The ARN of the Network Firewall. |
| <a name="output_firewall_id"></a> [firewall\_id](#output\_firewall\_id) | The ARN that identifies the firewall (same as arn). |
| <a name="output_firewall_status"></a> [firewall\_status](#output\_firewall\_status) | Nested list of information about the current status of the firewall. |
| <a name="output_firewall_update_token"></a> [firewall\_update\_token](#output\_firewall\_update\_token) | A string token used when updating the firewall. |
| <a name="output_logging_configuration_id"></a> [logging\_configuration\_id](#output\_logging\_configuration\_id) | The ARN of the associated firewall logging configuration. |
| <a name="output_policy_arn"></a> [policy\_arn](#output\_policy\_arn) | The ARN of the firewall policy. |
| <a name="output_policy_id"></a> [policy\_id](#output\_policy\_id) | The ARN that identifies the firewall policy. |
| <a name="output_policy_update_token"></a> [policy\_update\_token](#output\_policy\_update\_token) | A string token used when updating the firewall policy. |
| <a name="output_rule_group_arns"></a> [rule\_group\_arns](#output\_rule\_group\_arns) | Map of rule group keys to their ARNs. |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
