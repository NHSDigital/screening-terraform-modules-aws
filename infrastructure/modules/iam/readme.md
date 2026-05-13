# iam

Creates iam customer-managed policies and (optionally) iam roles for any
team on the screening platform. Naming and tagging come from the central
`tags` module via `context.tf`, so every team gets consistent
`/<service>/<project>/` paths and the standard NHS tag set automatically.

## Usage

The module is map-driven — one invocation can produce many policies and
roles. Three typical consumer patterns:

### 1. SSO customer-managed policies (no roles)

Use this when defining the iam policies that AWS Identity Center
permission sets will reference. The SSO wiring itself
(`aws_ssoadmin_permission_set`, `aws_ssoadmin_customer_managed_policy_attachment`,
account assignments) lives in the consumer stack, not in this module.

```hcl
data "aws_iam_policy_document" "readonly" {
  statement {
    actions   = ["s3:Get*", "s3:List*", "logs:Get*", "logs:Describe*"]
    resources = ["*"]
  }
}

module "iam" {
  source  = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/iam?ref=<tag>"
  context = module.label.context

  policies = {
    sso-readonly = {
      policy      = data.aws_iam_policy_document.readonly.json
      description = "Read-only access for the team's SSO permission set"
    }
  }
}
```

Reference the output from the SSO permission set in the consumer stack:

```hcl
resource "aws_ssoadmin_customer_managed_policy_attachment" "readonly" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.readonly.arn

  customer_managed_policy_reference {
    name = module.iam.policy_names["sso-readonly"]
    path = "/<service>/<project>/" # matches the module's default iam path
  }
}
```

> **Note:** customer-managed policies must exist in every account a
> permission set is provisioned into. Run this module in every workload
> account; the permission set lives once, in the Identity Center
> delegated admin account.

### 2. Service roles (no SSO)

Use this for ECS task roles, Lambda execution roles, EventBridge invoke
roles, etc.

```hcl
data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

module "iam" {
  source  = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/iam?ref=<tag>"
  context = module.label.context

  roles = {
    ecs-task = {
      assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
      description        = "ECS task role for the screening API"
      policy_arns = [
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
      ]
      inline_policies = {
        secrets = data.aws_iam_policy_document.read_secrets.json
      }
    }
  }
}
```

### 3. Role + matching policy in one call

Use `policy_keys` to wire a role to a policy created by *this same module
invocation* — useful for IRSA/OIDC trust patterns or any service role
whose policy you also want to manage here.

```hcl
module "iam" {
  source  = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/iam?ref=<tag>"
  context = module.label.context

  policies = {
    s3-data-rw = {
      policy      = data.aws_iam_policy_document.data_rw.json
      description = "Read/write to the screening data bucket"
    }
  }

  roles = {
    data-processor = {
      assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
      policy_keys        = ["s3-data-rw"]
    }
  }
}
```

## Conventions

- **Naming.** Resource names are derived from `module.this.id` plus an
  `attributes` suffix — e.g. `<id>-policy-<key>` and `<id>-role-<key>`.
- **iam path.** Defaults to `/<service>/<project>/` from context. Override
  globally with `var.path` or per-entry with `entry.path`.
- **Enabled switch.** Set `context.enabled = false` to disable the entire
  module (e.g. in development tfvars). All resources are gated by it.
- **Descriptions.** Strongly encouraged on every policy and role —
  whoever sees them in the iam console later will thank you.

## What this module does NOT do

- SSO permission sets, account assignments, group/user management — lives
  in the consumer stack via `aws_ssoadmin_*` and `aws_identitystore_*`.
- iam users, iam groups, SAML/OIDC identity providers
- Account-wide iam settings (password policy, account alias, MFA enforcement).

<!-- vale off -->
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_policy_label"></a> [policy_label](#module_policy_label) | `git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/tags` | feature/BCSS-23189-add-new-modules-to-suppport-bcss |
| <a name="module_role_label"></a> [role_label](#module_role_label) | `git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/tags` | feature/BCSS-23189-add-new-modules-to-suppport-bcss |
| <a name="module_this"></a> [this](#module_this) | `git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/tags` | feature/BCSS-23189-add-new-modules-to-suppport-bcss |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.internal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tag_map"></a> [additional_tag_map](#input_additional_tag_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`. | `map(string)` | `{}` | no |
| <a name="input_application_role"></a> [application_role](#input_application_role) | The role the application is performing | `string` | `"General"` | no |
| <a name="input_attributes"></a> [attributes](#input_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`, in the order they appear in the list. | `list(string)` | `[]` | no |
| <a name="input_aws_region"></a> [aws_region](#input_aws_region) | The AWS region | `string` | `"eu-west-2"` | no |
| <a name="input_context"></a> [context](#input_context) | Single object for setting entire context at once. See description of individual variables for details. | `any` | see `context.tf` | no |
| <a name="input_data_classification"></a> [data_classification](#input_data_classification) | Used to identify the data classification of the resource, e.g 1-5 | `string` | `"n/a"` | no |
| <a name="input_data_type"></a> [data_type](#input_data_type) | The tag data_type | `string` | `"None"` | no |
| <a name="input_delimiter"></a> [delimiter](#input_delimiter) | Delimiter to be used between ID elements. Defaults to `-` (hyphen). | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor_formats](#input_descriptor_formats) | Describe additional descriptors to be output in the `descriptors` output map. | `any` | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input_environment) | ID element. Usually used to indicate role, e.g. 'prd', 'dev', 'test', 'preprod', 'prod', 'uat' | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id_length_limit](#input_id_length_limit) | Limit `id` to this many characters (minimum 6). | `number` | `null` | no |
| <a name="input_label_key_case"></a> [label_key_case](#input_label_key_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module. | `string` | `null` | no |
| <a name="input_label_order"></a> [label_order](#input_label_order) | The order in which the labels (ID elements) appear in the `id`. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label_value_case](#input_label_value_case) | Controls the letter case of ID elements (labels) as included in `id`, set as tag values, and output by this module individually. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels_as_tags](#input_labels_as_tags) | Set of labels (ID elements) to include as tags in the `tags` output. | `set(string)` | `["default"]` | no |
| <a name="input_name"></a> [name](#input_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'. | `string` | `null` | no |
| <a name="input_on_off_pattern"></a> [on_off_pattern](#input_on_off_pattern) | Used to turn resources on and off based on a time pattern | `string` | `"n/a"` | no |
| <a name="input_owner"></a> [owner](#input_owner) | The name and or NHS.net email address of the service owner | `string` | `"None"` | no |
| <a name="input_path"></a> [path](#input_path) | Default IAM path applied to policies and roles when an entry does not override it. Defaults to `/<service>/<project>/` derived from context. | `string` | `null` | no |
| <a name="input_policies"></a> [policies](#input_policies) | Map of IAM customer-managed policies to create. See variables.tf for the schema. | <pre>map(object({<br/>    policy      = string<br/>    description = optional(string)<br/>    path        = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_project"></a> [project](#input_project) | ID element. A project identifier, indicating the name or role of the project the resource is for. | `string` | `null` | no |
| <a name="input_public_facing"></a> [public_facing](#input_public_facing) | Whether this resource is public facing | `bool` | `false` | no |
| <a name="input_regex_replace_chars"></a> [regex_replace_chars](#input_regex_replace_chars) | Terraform regular expression (regex) string. Characters matching the regex will be removed from the ID elements. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input_region) | ID element. Short region abbreviation e.g. 'uw2', 'ew2'. | `string` | `null` | no |
| <a name="input_roles"></a> [roles](#input_roles) | Map of IAM roles to create. See variables.tf for the schema. | <pre>map(object({<br/>    assume_role_policy   = string<br/>    description          = optional(string)<br/>    path                 = optional(string)<br/>    max_session_duration = optional(number, 3600)<br/>    permissions_boundary = optional(string)<br/>    policy_arns          = optional(list(string), [])<br/>    policy_keys          = optional(list(string), [])<br/>    inline_policies      = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_service"></a> [service](#input_service) | ID element. Service directorate abbreviation, e.g. 'bcss'. | `string` | `null` | no |
| <a name="input_service_category"></a> [service_category](#input_service_category) | The tag service_category | `string` | `"n/a"` | no |
| <a name="input_stack"></a> [stack](#input_stack) | ID element. The name of the stack/component, e.g. `database`, `web`, `waf`, `eks`. | `string` | `null` | no |
| <a name="input_tag_version"></a> [tag_version](#input_tag_version) | Used to identify the tagging version in use | `string` | `"1.0"` | no |
| <a name="input_tags"></a> [tags](#input_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`). | `map(string)` | `{}` | no |
| <a name="input_tool"></a> [tool](#input_tool) | The tool used to deploy the resource | `string` | `"Terraform"` | no |
| <a name="input_workspace"></a> [workspace](#input_workspace) | ID element. The Terraform workspace, to help ensure generated IDs are unique across workspaces. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policy_arns"></a> [policy_arns](#output_policy_arns) | Map of policy key -> ARN for every IAM policy created by this module. |
| <a name="output_policy_names"></a> [policy_names](#output_policy_names) | Map of policy key -> name for every IAM policy created by this module. |
| <a name="output_role_arns"></a> [role_arns](#output_role_arns) | Map of role key -> ARN for every IAM role created by this module. |
| <a name="output_role_names"></a> [role_names](#output_role_names) | Map of role key -> name for every IAM role created by this module. |
<!-- END_TF_DOCS -->
<!-- vale on -->
