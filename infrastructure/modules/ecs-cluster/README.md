# ECS Cluster

NHS Screening wrapper around the community
[`terraform-aws-modules/ecs/aws//modules/cluster`](https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws/latest/submodules/cluster)
module that enforces the platform's baseline controls.

## What this module enforces

|Control|How it is enforced|
|---|---|
|Creation gate|`create = module.this.enabled`|
|Naming and tagging|`name` derives from context, `tags = module.this.tags`|
|Container Insights|Enabled by default for cluster-level observability (~£0.03–0.04/container/hour)|
|ECS Exec session encryption|`execute_command_kms_key_id` REQUIRED if ECS Exec enabled (session data encrypted)|
|ECS Exec log destinations|CloudWatch Logs and/or S3; at least ONE required if ECS Exec enabled|
|Log destination encryption|Mandatory KMS encryption for CloudWatch Logs and S3 bucket logs|
|No public access by default|Module does not create security groups, ingress rules, or IAM roles|
|Baseline compliance|Encryption, audit trails, and network isolation enforced by design|

## Usage

### Minimal

```hcl
module "ecs_cluster" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/ecs-cluster?ref=<tag>"

  context = module.this.context
}
```

### Common production-style (CloudWatch + S3 dual logging)

```hcl
module "ecs_logs" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/cloudwatch-logs?ref=<tag>"

  context = module.this.context

  log_group_name       = "/bcss/ecs/prod/cluster-exec"
  retention_in_days    = 90
  kms_key_id           = module.kms.key_arn
  stream_names         = ["exec-sessions"]
}

module "ecs_cluster" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/ecs-cluster?ref=<tag>"

  context = module.this.context

  # CloudWatch destination for ECS Exec logs (mandatory if ECS Exec enabled)
  cloudwatch_log_group_name     = module.ecs_logs.cloudwatch_log_group_name
  cloud_watch_encryption_enabled = true

  # S3 destination for redundant session storage (optional)
  s3_bucket_name               = module.s3_ecs_exec_logs.bucket_id
  s3_bucket_encryption_enabled = true
  s3_kms_key_id               = module.kms.key_arn
  s3_key_prefix               = "ecs-exec-logs/"

  # Session-level encryption (always mandatory if ECS Exec enabled)
  execute_command_kms_key_id = module.kms.key_arn

  # Capacity provider configuration
  cluster_capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy = {
    FARGATE = {
      base   = 1
      weight = 70
    }
    FARGATE_SPOT = {
      weight = 30
    }
  }
}
```

### Advanced or edge case

```hcl
module "ecs_cluster" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/ecs-cluster?ref=<tag>"

  context = module.this.context

  enable_container_insights = false
  enable_execute_command    = false

  service_connect_defaults = {
    namespace = aws_service_discovery_http_namespace.shared.arn
  }
}
```

## Conventions

### Naming and Tagging

- Cluster name precedence: explicit `cluster_name` first, then context-derived `module.this.id`
- All tags sourced from `module.this.tags`; no direct tag parameter accepted
- Naming convention: `<service>-<environment>-<stack>-cluster` (derived from context)

### Container Insights

Container Insights is **enabled by default** (`enable_container_insights = true`) for cluster-level observability:

- **Cost impact**: ~£0.03–0.04/container/hour (typical ECS cluster)
- **Metrics collected**: CPU, memory, disk, network utilization per container
- **Log destination**: CloudWatch Logs (`/aws/ecs/containerinsights/<cluster-name>/performance`)
- **Retention**: 30 days (separate from ECS Exec logs)
- **Disable if**: Testing or non-critical development environments (use `enable_container_insights = false`)

### ECS Exec: Three Logging Levels

When `enable_execute_command = true`, sessions can be logged at three levels:

| Level | How | Storage | Encryption | Use Case |
|-------|-----|---------|------------|----------|
| **Container Insights** | Cluster metric collection | CloudWatch Logs | AWS-managed key | Operational metrics (CPU, memory) |
| **ECS Exec sessions** | Caller command/output | CloudWatch Logs AND/OR S3 | ✅ Mandatory KMS | Audit trail, troubleshooting |
| **Task application logs** | Application stdout/stderr | Configured per task definition | Per-task driver config | Debugging, monitoring |

### ECS Exec: Encryption and Destinations

When `enable_execute_command = true`:

- **Session encryption** (`execute_command_kms_key_id`): **REQUIRED**. All session data encrypted with this KMS key.
- **Log destinations**: At least ONE required:
  - **CloudWatch Logs**: `cloudwatch_log_group_name` + `cloud_watch_encryption_enabled`
  - **S3**: `s3_bucket_name` + `s3_bucket_encryption_enabled` + `s3_kms_key_id`
  - **Both**: Supported simultaneously for redundancy (recommended for production)

### ECS Exec Log Group Management

- **CloudWatch log group**: Pre-created externally via `cloudwatch-logs` module (not inline by this module)
- **Retention baseline**: 90 days (exceeds AWS 30-day audit minimum)
- **KMS encryption**: Mandatory for security compliance
- **Log group class**: Optional (`STANDARD` or `INFREQUENT_ACCESS` for cost optimization)

### Caller Responsibilities

This module handles **cluster-level** configuration only. Callers are responsible for:

1. **Security groups**: Create and manage via dedicated SG module
   - Ingress: Allow ephemeral ports (32768–65535) from ALB/NLB task target groups
   - Egress: Allow HTTPS 443 (ECR, CloudWatch), UDP 53 (DNS)

2. **CloudWatch log group** (if using CloudWatch for ECS Exec): Create via `cloudwatch-logs` module
   - Must have KMS encryption enabled
   - Must use `/path/format` naming convention

3. **S3 bucket** (if using S3 for ECS Exec): Create via `s3-bucket` module
   - Must have encryption enabled
   - Must have KMS key specified for ECS Exec logs

4. **IAM roles**: Create `task-exec` and `infrastructure` roles in caller stack
   - Module does not create these (enforced by `create_*_iam_role = false`)

5. **Task definitions and services**: Define separately (outside this module)

### Disabling ECS Exec

If `enable_execute_command = false`:

- No log group, S3 bucket, or session encryption needed
- ECS Exec is unavailable for this cluster
- Container Insights still available (independent setting)

---

## Logging Architecture: Best Practices

### Why CloudWatch + S3 Together?

**CloudWatch Logs** (real-time access):

- Immediate visibility of ECS Exec sessions
- CloudWatch Logs Insights queries for troubleshooting
- Cost: Low volume for typical session logs (< £0.50/month)

**S3** (long-term archive):

- Durable, immutable audit trail
- Cost-effective retention (Glacier for old sessions)
- Compliance: HIPAA, SOC 2 audit requirements
- Search: Athena queries across historical logs

**Combined approach** (recommended):

```hcl
# Real-time: CloudWatch
cloudwatch_log_group_name = module.ecs_logs.cloudwatch_log_group_name
cloud_watch_encryption_enabled = true

# Archive: S3
s3_bucket_name = module.s3_archive.bucket_id
s3_bucket_encryption_enabled = true
s3_kms_key_id = module.kms.key_arn
```

### IAM Policy Baseline (Task Execution Role)

The `task-exec` IAM role must include permissions for:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:REGION:ACCOUNT:log-group:/aws/ecs/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:REGION:ACCOUNT:key/KEY_ID"
    }
  ]
}
```

---

## What this module does NOT do

- **Does not create security groups or manage ingress/egress rules.** Callers must create a security group and pass it to ECS services/tasks. Required rules:
  - Ingress: Ephemeral ports (32768–65535) from ALB/NLB
  - Egress: HTTPS 443 (ECR, CloudWatch), UDP 53 (DNS), optional HTTPS 443 to other services

- **Does not create or manage IAM roles/policies.** Callers must create:
  - `ecs:task-exec` role for task execution (pull images, write logs, decrypt KMS)
  - `ecs:infrastructure` role for managed instances (EC2 lifecycle)
  - `ecs:node` role for managed instance node IAM profile

- **Does not configure task-level application logging.** Callers specify logging drivers in task definitions:
  - `awslogs`: CloudWatch Logs (common)
  - `splunk`: Splunk HTTP Event Collector
  - `awsfirelens`: Route logs via Fluent Bit/Logstash

- **Does not create CloudWatch alarms.** Alarms (CPU, memory, task failures) are a separate responsibility. Consider:
  - Task count alarms (desired vs. running)
  - CPU/memory utilization alarms
  - ECS service deployment alarms

- **Does not configure Service Connect.** The optional `service_connect_defaults` parameter allows consumers to enable it; this module does not enforce or configure it.

- **Does not manage scaling policies.** Auto-scaling (target-tracking, step-based) is configured at the service or capacity provider level, not the cluster.

- **Does not validate external resources (security groups, log groups, KMS keys).** Callers must ensure these resources exist and have correct policies before applying this module.

- **Does not configure cluster auto-scaling** (e.g., managed instances scale-in protection, warm pool sizing). These are handled by capacity provider or ASG configuration outside this module.

---

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.34 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.13 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_ecs_cluster"></a> [ecs\_cluster](#module\_ecs\_cluster) | terraform-aws-modules/ecs/aws//modules/cluster | 7.5.0 |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [terraform_data.validations](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_application_role"></a> [application\_role](#input\_application\_role) | The role the application is performing | `string` | `"General"` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_cloud_watch_encryption_enabled"></a> [cloud\_watch\_encryption\_enabled](#input\_cloud\_watch\_encryption\_enabled) | Whether to enable encryption for ECS Exec logs stored in CloudWatch Logs. Encryption is mandatory when using CloudWatch destination. | `bool` | `true` | no |
| <a name="input_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#input\_cloudwatch\_log\_group\_name) | Optional name of a pre-created CloudWatch Log Group for ECS Exec session logs.<br/>The log group must be created separately via the cloudwatch-logs module.<br/>Either cloudwatch\_log\_group\_name or s3\_bucket\_name must be provided<br/>if enable\_execute\_command is true.<br/>Example: /bcss/app/prod/ecs/cluster-exec-logs | `string` | `null` | no |
| <a name="input_cluster_capacity_providers"></a> [cluster\_capacity\_providers](#input\_cluster\_capacity\_providers) | Capacity provider names to associate with the ECS cluster. | `list(string)` | <pre>[<br/>  "FARGATE"<br/>]</pre> | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Optional ECS cluster name. When null, this module uses module.this.id. | `string` | `null` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "project": null,<br/>  "regex_replace_chars": null,<br/>  "region": null,<br/>  "service": null,<br/>  "stack": null,<br/>  "tags": {},<br/>  "terraform_source": null,<br/>  "workspace": null<br/>}</pre> | no |
| <a name="input_data_classification"></a> [data\_classification](#input\_data\_classification) | Used to identify the data classification of the resource, e.g 1-5 | `string` | `"n/a"` | no |
| <a name="input_data_type"></a> [data\_type](#input\_data\_type) | The tag data\_type | `string` | `"None"` | no |
| <a name="input_default_capacity_provider_strategy"></a> [default\_capacity\_provider\_strategy](#input\_default\_capacity\_provider\_strategy) | Default capacity provider strategy definitions keyed by provider name. | <pre>map(object({<br/>    base   = optional(number)<br/>    weight = optional(number)<br/>  }))</pre> | <pre>{<br/>  "FARGATE": {<br/>    "weight": 100<br/>  }<br/>}</pre> | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>    format = string<br/>    labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_enable_container_insights"></a> [enable\_container\_insights](#input\_enable\_container\_insights) | Whether to enable CloudWatch Container Insights at cluster level. | `bool` | `true` | no |
| <a name="input_enable_execute_command"></a> [enable\_execute\_command](#input\_enable\_execute\_command) | Whether to enable ECS Exec configuration at cluster level. | `bool` | `true` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_execute_command_kms_key_id"></a> [execute\_command\_kms\_key\_id](#input\_execute\_command\_kms\_key\_id) | KMS key ARN or ID for encrypting ECS Exec session data. Required if enable\_execute\_command is true. | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_on_off_pattern"></a> [on\_off\_pattern](#input\_on\_off\_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_s3_bucket_encryption_enabled"></a> [s3\_bucket\_encryption\_enabled](#input\_s3\_bucket\_encryption\_enabled) | Whether to enforce encryption on the S3 bucket used for ECS Exec session logs.<br/>If s3\_bucket\_name is provided, this must be set to true.<br/>Encryption is mandatory for ECS Exec session data. | `bool` | `null` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | Optional S3 bucket name for ECS Exec session logs.<br/>Either cloudwatch\_log\_group\_name or s3\_bucket\_name must be provided<br/>if enable\_execute\_command is true. If specified, s3\_bucket\_encryption\_enabled<br/>must be set to true (encryption is mandatory).<br/>Example: bcss-prod-ecs-exec-logs | `string` | `null` | no |
| <a name="input_s3_key_prefix"></a> [s3\_key\_prefix](#input\_s3\_key\_prefix) | Optional S3 key prefix for storing ECS Exec session logs.<br/>All session logs will be stored under this prefix in the S3 bucket.<br/>If not provided, logs are stored at the bucket root.<br/>Example: ecs-exec-logs/ or prod/ecs-exec/ | `string` | `null` | no |
| <a name="input_s3_kms_key_id"></a> [s3\_kms\_key\_id](#input\_s3\_kms\_key\_id) | Optional KMS key ARN or ID to use for encrypting ECS Exec session logs in S3.<br/>Only relevant if s3\_bucket\_name is provided and s3\_bucket\_encryption\_enabled is true.<br/>Example: arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012 | `string` | `null` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_service_connect_defaults"></a> [service\_connect\_defaults](#input\_service\_connect\_defaults) | Optional default Service Connect namespace configuration. | <pre>object({<br/>    namespace = string<br/>  })</pre> | `null` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to the caller module path when not set. | `string` | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | CloudWatch Log Group ARN used for ECS Exec logs when enabled. |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | CloudWatch Log Group name used for ECS Exec logs when enabled. |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | ARN that identifies the ECS cluster. |
| <a name="output_cluster_capacity_providers"></a> [cluster\_capacity\_providers](#output\_cluster\_capacity\_providers) | Map of cluster capacity provider attributes. |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | ID that identifies the ECS cluster. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name that identifies the ECS cluster. |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
