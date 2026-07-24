# VPC

Screening wrapper around the [`terraform-aws-modules/vpc/aws`](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest) upstream module (v6.6.1), providing a standardised four-tier subnet layout.

## Breaking change

This module is a breaking replacement for the original local `vpc` module.

Consumers must review and update module calls before upgrading, including:

- Input variables and defaults
- Output names and semantics
- Routing behaviour when enabling Network Firewall mode
- Flow log configuration and tagging

Treat adoption of this module as a migration, not a drop-in swap.

## Subnet tiers

| Tier | Prefix | Purpose |
| --- | --- | --- |
| Firewall | /28 | Network Firewall endpoints |
| Public | /24 | Public-facing resources, NAT gateways |
| Private | /23 | Private workloads with internet access via NAT Gateway |
| Intra | /23 | Intra, no internet route via NAT Gateway |

Subnet CIDRs are auto-calculated from the VPC CIDR across the first three available AZs in the region by default. Set `availability_zones` to pin a specific AZ list or to use a different AZ count. Explicit CIDR overrides are available via `firewall_subnets`, `public_subnets`, `private_subnets`, and `intra_subnets`.

**Auto-calculation logic:** The module uses Terraform's `cidrsubnets()` function to carve non-overlapping subnets from the VPC CIDR, sizing each tier per the `*_subnet_prefix` variables. For example:

- VPC CIDR `/20` with `firewall_subnet_prefix = 28` → /28 subnets (8 extra bits carved out)
- VPC CIDR `/16` with `public_subnet_prefix = 24` → /24 subnets (8 extra bits carved out)

**AWS sizing constraints** (automatically validated):

- VPC CIDR block: `/16` to `/28` netmask
- Subnet CIDR block: `/16` to `/28` netmask
- Subnet prefix must be larger (numerically) than VPC prefix (so subnets can be carved from the VPC)
- Smaller VPC CIDRs may require larger subnet prefixes or explicit subnet overrides when the requested subnet count cannot fit inside the CIDR range

## Features

- **Naming and tagging** via `context.tf` / `module.this` (tags module v2.5.0)
- **NAT gateways** — one per AZ by default, with `single_nat_gateway` option for cost savings
- **VPC Flow Logs** — enabled by default, sending to CloudWatch Logs with a 365-day retention. Implemented as standalone resources (upstream deprecated flow logs in v6.x, removing in v7.0.0)
- **Security defaults** — default security group adopted and stripped of all rules
- **Firewall subnets** — standalone resources (upstream module has no firewall tier)

## Usage

### Standard VPC (all subnet tiers)

```terraform
module "vpc" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/vpc?ref=<version>"

  environment = "prod"
  service     = "bcss"
  name        = "vpc"

  vpc_cidr           = "10.0.0.0/16"
  single_nat_gateway = false  # one NAT per AZ for HA

  flow_log_kms_key_id = aws_kms_key.cloudwatch.arn  # optional encryption
}
```

### Database VPC (intra subnets only, /24 CIDR)

Minimal VPC for databases with no internet access. Uses /26 intra subnets (64 IPs × 3 AZs).

```terraform
module "database_vpc" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/vpc?ref=<version>"

  environment = "prod"
  service     = "bcss"
  name        = "database"

  vpc_cidr = "10.1.0.0/24"

  # Intra subnets only — disable other tiers
  create_firewall_subnets = false
  create_public_subnets   = false
  create_private_subnets  = false
  create_intra_subnets    = true

  # Adjust subnet prefix for /24 VPC (must be larger than /24, e.g., /26, /27, /28)
  intra_subnet_prefix = 26

  enable_flow_log            = true
  flow_log_retention_in_days = 30
}
```

### Network Firewall routing (firewall + public subnets only)

For centralized Network Firewall inspection. Public subnets route outbound traffic via firewall VPCE (not IGW).

```terraform
module "vpc_nfw" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/vpc?ref=<version>"

  environment = "prod"
  service     = "bcss"
  name        = "nfw"

  vpc_cidr = "10.0.0.0/16"

  # Firewall + public only — disable private and intra
  create_firewall_subnets = true
  create_public_subnets   = true
  create_private_subnets  = false
  create_intra_subnets    = false

  enable_network_firewall = true  # enables firewall routing mode

  # Inject 0.0.0.0/0 → firewall VPCE into public route tables at stack level
}
```

### Minimal public-only scenario

For simple public-facing resources without private egress.

```terraform
module "vpc_public" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/vpc?ref=<version>"

  environment = "dev"
  service     = "test"
  name        = "public"

  vpc_cidr = "10.0.0.0/16"

  # Public subnets only
  create_firewall_subnets = false
  create_public_subnets   = true
  create_private_subnets  = false
  create_intra_subnets    = false

  map_public_ip_on_launch = true  # auto-assign public IPs
}
```

## Key variables

| Variable | Description | Default |
| --- | --- | --- |
| `vpc_cidr` | VPC CIDR block (/16 to /28 per AWS limits) | Required |
| `create_firewall_subnets` | Whether to create firewall subnets (required for Network Firewall routing mode) | `true` |
| `create_public_subnets` | Whether to create public subnets (internet-facing resources, NAT gateways) | `true` |
| `create_private_subnets` | Whether to create private subnets (NAT-routed workloads with internet access) | `true` |
| `create_intra_subnets` | Whether to create intra subnets (no internet access) | `true` |
| `availability_zones` | Explicit AZs for subnet placement; defaults to the first three available AZs | `null` |
| `single_nat_gateway` | Use one shared NAT instead of per-AZ | `false` |
| `enable_flow_log` | Enable VPC flow logs | `true` |
| `flow_log_retention_in_days` | CloudWatch log retention | `365` |
| `flow_log_traffic_type` | ACCEPT, REJECT, or ALL | `ALL` |
| `flow_log_kms_key_id` | KMS key ARN for log encryption | `null` |
| `map_public_ip_on_launch` | Auto-assign public IPs in public subnets | `false` |

## Key outputs

| Output | Description |
| --- | --- |
| `vpc_id` | The VPC ID |
| `public_subnet_ids` | Public subnet IDs |
| `private_subnet_ids` | Private (NAT-routed) subnet IDs |
| `intra_subnet_ids` | Intra (no internet) subnet IDs |
| `firewall_subnet_ids` | Firewall subnet IDs |
| `nat_public_ips` | NAT gateway Elastic IPs |
| `flow_log_id` | VPC Flow Log ID |

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.42 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.51.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_flow_log"></a> [flow\_log](#module\_flow\_log) | terraform-aws-modules/vpc/aws//modules/flow-log | 6.6.1 |
| <a name="module_this"></a> [this](#module\_this) | ../tags | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 6.6.1 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_route.firewall_to_igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.edge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.edge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [terraform_data.validations](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_application_role"></a> [application\_role](#input\_application\_role) | The role the application is performing | `string` | `"General"` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | Availability zones to use for the VPC. Leave null to use the first three available AZs in the current region. | `list(string)` | `null` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_cloudwatch_log_group_tags"></a> [cloudwatch\_log\_group\_tags](#input\_cloudwatch\_log\_group\_tags) | Additional tags for the CloudWatch log group. | `map(string)` | `{}` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "project": null,<br/>  "regex_replace_chars": null,<br/>  "region": null,<br/>  "service": null,<br/>  "stack": null,<br/>  "tags": {},<br/>  "terraform_source": null,<br/>  "workspace": null<br/>}</pre> | no |
| <a name="input_create_firewall_subnets"></a> [create\_firewall\_subnets](#input\_create\_firewall\_subnets) | Whether to create firewall subnets (required for Network Firewall routing mode). | `bool` | `true` | no |
| <a name="input_create_intra_subnets"></a> [create\_intra\_subnets](#input\_create\_intra\_subnets) | Whether to create intra subnets (no internet access). | `bool` | `true` | no |
| <a name="input_create_private_subnets"></a> [create\_private\_subnets](#input\_create\_private\_subnets) | Whether to create private subnets (workloads with outbound internet access via NAT gateway). | `bool` | `true` | no |
| <a name="input_create_public_subnets"></a> [create\_public\_subnets](#input\_create\_public\_subnets) | Whether to create public subnets (internet-facing resources, NAT gateways). | `bool` | `true` | no |
| <a name="input_data_classification"></a> [data\_classification](#input\_data\_classification) | Used to identify the data classification of the resource, e.g 1-5 | `string` | `"n/a"` | no |
| <a name="input_data_type"></a> [data\_type](#input\_data\_type) | The tag data\_type | `string` | `"None"` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>    format = string<br/>    labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_dhcp_options_domain_name"></a> [dhcp\_options\_domain\_name](#input\_dhcp\_options\_domain\_name) | The suffix domain name to use by default when resolving non-FQDNs. | `string` | `""` | no |
| <a name="input_dhcp_options_domain_name_servers"></a> [dhcp\_options\_domain\_name\_servers](#input\_dhcp\_options\_domain\_name\_servers) | List of DNS server addresses for the DHCP option set. Use ['AmazonProvidedDNS'] for the default VPC resolver, or Route 53 Resolver inbound endpoint IPs. | `list(string)` | <pre>[<br/>  "AmazonProvidedDNS"<br/>]</pre> | no |
| <a name="input_dhcp_options_ntp_servers"></a> [dhcp\_options\_ntp\_servers](#input\_dhcp\_options\_ntp\_servers) | List of NTP servers for the DHCP option set. | `list(string)` | `[]` | no |
| <a name="input_dhcp_options_tags"></a> [dhcp\_options\_tags](#input\_dhcp\_options\_tags) | Additional tags for the DHCP option set. | `map(string)` | `{}` | no |
| <a name="input_enable_dhcp_options"></a> [enable\_dhcp\_options](#input\_enable\_dhcp\_options) | Create a custom DHCP option set and associate it with the VPC. | `bool` | `false` | no |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | Enable DNS hostnames in the VPC. | `bool` | `true` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | Enable DNS support in the VPC. | `bool` | `true` | no |
| <a name="input_enable_flow_log"></a> [enable\_flow\_log](#input\_enable\_flow\_log) | Enable VPC flow logs to CloudWatch Logs. | `bool` | `true` | no |
| <a name="input_enable_network_firewall"></a> [enable\_network\_firewall](#input\_enable\_network\_firewall) | When true, the VPC module creates firewall subnets, takes over<br/>IGW management from the community module, and reconfigures<br/>routing for AWS Network Firewall inspection:<br/>  - Firewall subnets created as standalone resources<br/>  - IGW created as a standalone resource (community module's create\_igw = false)<br/>  - Firewall subnets get a default route (0.0.0.0/0) to the IGW<br/>  - Public subnet default route is NOT created (callers must<br/>    inject 0.0.0.0/0 → firewall VPCE at the stack level)<br/>When false (default), no firewall subnets are created, the<br/>community module creates the IGW and public → IGW route as<br/>normal — no Network Firewall in the path. | `bool` | `false` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_firewall_subnet_prefix"></a> [firewall\_subnet\_prefix](#input\_firewall\_subnet\_prefix) | Prefix length for firewall subnets (e.g. 28 = /28, 16 IPs each). AWS allows /16 to /28. Must be more specific (larger numerically) than vpc\_cidr when auto-calculating. Used only when firewall\_subnets list is empty; when explicit firewall\_subnets are provided, this value is ignored. Highly recommended: /28 to minimize wasted IPs. | `number` | `28` | no |
| <a name="input_firewall_subnet_tags"></a> [firewall\_subnet\_tags](#input\_firewall\_subnet\_tags) | Additional tags for the firewall subnets. | `map(string)` | `{}` | no |
| <a name="input_firewall_subnets"></a> [firewall\_subnets](#input\_firewall\_subnets) | Explicit CIDR blocks for firewall subnets (one per AZ). Leave empty to auto-calculate. | `list(string)` | `[]` | no |
| <a name="input_flow_log_kms_key_id"></a> [flow\_log\_kms\_key\_id](#input\_flow\_log\_kms\_key\_id) | ARN of a KMS key to encrypt the CloudWatch log group. Leave null for no encryption. | `string` | `null` | no |
| <a name="input_flow_log_max_aggregation_interval"></a> [flow\_log\_max\_aggregation\_interval](#input\_flow\_log\_max\_aggregation\_interval) | The maximum interval of time (seconds) during which a flow of packets is captured. Valid values: 60 (1 min) or 600 (10 min). | `number` | `600` | no |
| <a name="input_flow_log_retention_in_days"></a> [flow\_log\_retention\_in\_days](#input\_flow\_log\_retention\_in\_days) | Number of days to retain VPC flow logs in CloudWatch. | `number` | `365` | no |
| <a name="input_flow_log_tags"></a> [flow\_log\_tags](#input\_flow\_log\_tags) | Additional tags for the VPC flow log. | `map(string)` | `{}` | no |
| <a name="input_flow_log_traffic_type"></a> [flow\_log\_traffic\_type](#input\_flow\_log\_traffic\_type) | The type of traffic to capture. Valid values: ACCEPT, REJECT, ALL. | `string` | `"ALL"` | no |
| <a name="input_iam_role_tags"></a> [iam\_role\_tags](#input\_iam\_role\_tags) | Additional tags for the IAM role used by the VPC flow log. | `map(string)` | `{}` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_intra_subnet_prefix"></a> [intra\_subnet\_prefix](#input\_intra\_subnet\_prefix) | Prefix length for intra subnets with no internet route (e.g. 23 = /23, 512 IPs each). AWS allows /16 to /28. Must be more specific (larger numerically) than vpc\_cidr when auto-calculating. Used only when intra\_subnets list is empty; when explicit intra\_subnets are provided, this value is ignored. | `number` | `23` | no |
| <a name="input_intra_subnet_tags"></a> [intra\_subnet\_tags](#input\_intra\_subnet\_tags) | Additional tags for the intra (no-internet) subnets. | `map(string)` | `{}` | no |
| <a name="input_intra_subnets"></a> [intra\_subnets](#input\_intra\_subnets) | Explicit CIDR blocks for intra subnets with no internet route (one per AZ). Leave empty to auto-calculate. | `list(string)` | `[]` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_manage_default_network_acl"></a> [manage\_default\_network\_acl](#input\_manage\_default\_network\_acl) | Adopt and manage the default network ACL. | `bool` | `true` | no |
| <a name="input_manage_default_security_group"></a> [manage\_default\_security\_group](#input\_manage\_default\_security\_group) | Adopt and manage the default security group, removing all inline rules. | `bool` | `true` | no |
| <a name="input_map_public_ip_on_launch"></a> [map\_public\_ip\_on\_launch](#input\_map\_public\_ip\_on\_launch) | Auto-assign public IPs to instances launched in public subnets. | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_on_off_pattern"></a> [on\_off\_pattern](#input\_on\_off\_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_private_subnet_prefix"></a> [private\_subnet\_prefix](#input\_private\_subnet\_prefix) | Prefix length for private subnets with NAT (e.g. 23 = /23, 512 IPs each). AWS allows /16 to /28. Must be more specific (larger numerically) than vpc\_cidr when auto-calculating. Used only when private\_subnets list is empty; when explicit private\_subnets are provided, this value is ignored. | `number` | `23` | no |
| <a name="input_private_subnet_tags"></a> [private\_subnet\_tags](#input\_private\_subnet\_tags) | Additional tags for the private (NAT-routed) subnets. | `map(string)` | `{}` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | Explicit CIDR blocks for private subnets with NAT (one per AZ). Leave empty to auto-calculate. | `list(string)` | `[]` | no |
| <a name="input_project"></a> [project](#input\_project) | ID element. A project identifier, indicating the name or role of the project the resource is for, such as `website` or `api` | `string` | `null` | no |
| <a name="input_public_facing"></a> [public\_facing](#input\_public\_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_public_subnet_prefix"></a> [public\_subnet\_prefix](#input\_public\_subnet\_prefix) | Prefix length for public subnets (e.g. 24 = /24, 256 IPs each). AWS allows /16 to /28. Must be more specific (larger numerically) than vpc\_cidr when auto-calculating. Used only when public\_subnets list is empty; when explicit public\_subnets are provided, this value is ignored. | `number` | `24` | no |
| <a name="input_public_subnet_tags"></a> [public\_subnet\_tags](#input\_public\_subnet\_tags) | Additional tags for the public subnets. | `map(string)` | `{}` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | Explicit CIDR blocks for public subnets (one per AZ). Leave empty to auto-calculate. | `list(string)` | `[]` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | ID element \_(Rarely used, not included by default)\_.  Usually an abbreviation of the selected AWS region e.g. 'uw2', 'ew2' or 'gbl' for resources like IAM roles that have no region | `string` | `null` | no |
| <a name="input_service"></a> [service](#input\_service) | ID element. Usually an abbreviation of your service directorate name, e.g. 'bcss' or 'csms', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_service_category"></a> [service\_category](#input\_service\_category) | The tag service\_category | `string` | `"n/a"` | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | Provision a single shared NAT Gateway instead of one per AZ. Saves cost but reduces availability. | `bool` | `false` | no |
| <a name="input_stack"></a> [stack](#input\_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks` | `string` | `null` | no |
| <a name="input_tag_version"></a> [tag\_version](#input\_tag\_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to the caller module path when not set. | `string` | `null` | no |
| <a name="input_tool"></a> [tool](#input\_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The IPv4 CIDR block for the VPC (AWS allows /16 to /28 netmask). Subnet CIDR blocks are auto-calculated from this VPC CIDR using the *\_subnet\_prefix variables. | `string` | n/a | yes |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_azs"></a> [azs](#output\_azs) | The availability zones used by this VPC. |
| <a name="output_default_security_group_id"></a> [default\_security\_group\_id](#output\_default\_security\_group\_id) | The ID of the default security group. |
| <a name="output_edge_route_table_id"></a> [edge\_route\_table\_id](#output\_edge\_route\_table\_id) | ID of the IGW edge route table (only when enable\_network\_firewall = true). |
| <a name="output_firewall_route_table_ids"></a> [firewall\_route\_table\_ids](#output\_firewall\_route\_table\_ids) | List of IDs of the firewall route tables. |
| <a name="output_firewall_subnet_ids"></a> [firewall\_subnet\_ids](#output\_firewall\_subnet\_ids) | List of IDs of the firewall subnets. |
| <a name="output_firewall_subnets_cidr_blocks"></a> [firewall\_subnets\_cidr\_blocks](#output\_firewall\_subnets\_cidr\_blocks) | List of CIDR blocks of the firewall subnets. |
| <a name="output_flow_log_arn"></a> [flow\_log\_arn](#output\_flow\_log\_arn) | The ARN of the VPC Flow Log. |
| <a name="output_flow_log_cloudwatch_log_group_arn"></a> [flow\_log\_cloudwatch\_log\_group\_arn](#output\_flow\_log\_cloudwatch\_log\_group\_arn) | The ARN of the CloudWatch Log Group for VPC flow logs. |
| <a name="output_flow_log_iam_role_arn"></a> [flow\_log\_iam\_role\_arn](#output\_flow\_log\_iam\_role\_arn) | The ARN of the IAM role used by VPC flow logs. |
| <a name="output_flow_log_id"></a> [flow\_log\_id](#output\_flow\_log\_id) | The ID of the VPC Flow Log. |
| <a name="output_igw_arn"></a> [igw\_arn](#output\_igw\_arn) | The ARN of the Internet Gateway. |
| <a name="output_igw_id"></a> [igw\_id](#output\_igw\_id) | The ID of the Internet Gateway. |
| <a name="output_intra_route_table_ids"></a> [intra\_route\_table\_ids](#output\_intra\_route\_table\_ids) | List of IDs of the intra route tables. |
| <a name="output_intra_subnet_ids"></a> [intra\_subnet\_ids](#output\_intra\_subnet\_ids) | List of IDs of the intra subnets (no internet route). |
| <a name="output_intra_subnets_cidr_blocks"></a> [intra\_subnets\_cidr\_blocks](#output\_intra\_subnets\_cidr\_blocks) | List of CIDR blocks of the intra subnets. |
| <a name="output_nat_gateway_ids"></a> [nat\_gateway\_ids](#output\_nat\_gateway\_ids) | List of NAT Gateway IDs. |
| <a name="output_nat_public_ips"></a> [nat\_public\_ips](#output\_nat\_public\_ips) | List of public Elastic IPs created for NAT Gateways. |
| <a name="output_private_route_table_ids"></a> [private\_route\_table\_ids](#output\_private\_route\_table\_ids) | List of IDs of the private route tables. |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | List of IDs of the private subnets (routed via NAT). |
| <a name="output_private_subnets_cidr_blocks"></a> [private\_subnets\_cidr\_blocks](#output\_private\_subnets\_cidr\_blocks) | List of CIDR blocks of the private subnets. |
| <a name="output_public_route_table_ids"></a> [public\_route\_table\_ids](#output\_public\_route\_table\_ids) | List of IDs of the public route tables. |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | List of IDs of the public subnets. |
| <a name="output_public_subnets_cidr_blocks"></a> [public\_subnets\_cidr\_blocks](#output\_public\_subnets\_cidr\_blocks) | List of CIDR blocks of the public subnets. |
| <a name="output_vpc_arn"></a> [vpc\_arn](#output\_vpc\_arn) | The ARN of the VPC. |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | The primary CIDR block of the VPC. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC. |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
