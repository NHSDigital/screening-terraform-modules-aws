# Cognito

NHS Screening wrapper around the community
[`lgallard/cognito-user-pool/aws`](https://registry.terraform.io/modules/lgallard/cognito-user-pool/aws/4.0.2)
module that enforces the platform's baseline controls and consumes
the shared `context.tf` for naming and tagging.

It keeps the default pool/domain/schema behaviour from the existing bespoke
module where practical, but deliberately avoids carrying forward the old
Secrets Manager password flow.

## Design choices

* Uses the upstream `lgallard/cognito-user-pool/aws` module pinned to `4.0.2`
* Derives the user pool name from `user_pool_name`, then `name_prefix`, then the
  shared context-derived module ID
* Creates a Cognito domain by default, following the prior module behaviour
* Enables `ignore_schema_changes = true` by default because this is recommended
  for new Cognito deployments with custom schemas
* Keeps a small compatibility layer for legacy inputs such as `name_prefix` and
  `attribute_names`
* Narrows application client configuration to an `app_clients` interface instead
  of exposing the upstream generic `clients`, `resource_servers`, `user_groups`,
  and `identity_providers` inputs directly
* Supports optional bootstrap user creation because the current BCSS Cognito
  stacks still provision initial users during stack deployment

## Usage

```hcl
module "cognito" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/cognito?ref=main"

  name        = "cognito"
  project     = "shared"
  environment = "dev"

  app_clients = [
    {
      callback_urls        = ["https://example.internal/login/oauth2/code/nhs-identity"]
      logout_urls          = ["https://example.internal/logout"]
      default_redirect_uri = "https://example.internal/login/oauth2/code/nhs-identity"

      allowed_oauth_flows_user_pool_client = true
      allowed_oauth_flows                  = ["code"]
      allowed_oauth_scopes = [
        "email",
        "openid",
        "profile",
        "aws.cognito.signin.user.admin",
      ]
      supported_identity_providers = ["COGNITO"]
      generate_secret              = true
    }
  ]

  bootstrap_users = [
    {
      uuid               = "11111111-1111-1111-1111-111111111111"
      bcss_username      = "test.user"
      id_assurance_level = "3"
      rbac_role          = "[{activities=[BS-Select], activity_codes=[B1808]}]"
    }
  ]
}
```

## Current defaults inherited from the old module

* `auto_verified_attributes = ["email"]`
* `mfa_configuration = "OFF"`
* `admin_create_user_config.allow_admin_create_user_only = false`
* `email_configuration.email_sending_account = "COGNITO_DEFAULT"`
* `verification_message_template.default_email_option = "CONFIRM_WITH_CODE"`
* `username_configuration.case_sensitive = false`
* `attribute_names` produces the same default custom string attributes as the old module
* `bootstrap_users` can be used to preserve the current stack behavior where Cognito users are created during deployment

## What this module does NOT do

* It does not create or replicate a Secrets Manager password secret
* It does not create the KMS keys or SSM parameters used by the older external
  and training stacks; those remain stack-level concerns and can consume this
  module's outputs instead

The wrapper does not directly expose the upstream generic inputs for:

* identity providers
* resource servers
* user groups
* arbitrary client definitions beyond the curated `app_clients` OAuth client shape

If those become required later, they can be added back with an explicit shared-resources use case.

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.42 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 1.89 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.50.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_cognito"></a> [cognito](#module\_cognito) | lgallard/cognito-user-pool/aws | 4.0.2 |
| <a name="module_this"></a> [this](#module\_this) | git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/tags | v2.6.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cognito_user.bootstrap_users](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_acr"></a> [acr](#input\_acr) | ACR attribute applied to bootstrap Cognito users. | `string` | `"AAL1_USERPASS"` | no |
| <a name="input_amr"></a> [amr](#input\_amr) | AMR attribute applied to bootstrap Cognito users. | `string` | `"USERPASS"` | no |
| <a name="input_app_clients"></a> [app\_clients](#input\_app\_clients) | List of Cognito application clients to create. This wrapper intentionally supports the shared-resources OAuth client pattern rather than the full upstream clients surface. | <pre>list(object({<br/>    name                                          = optional(string)<br/>    callback_urls                                 = list(string)<br/>    logout_urls                                   = optional(list(string), [])<br/>    default_redirect_uri                          = optional(string)<br/>    generate_secret                               = optional(bool, true)<br/>    auth_session_validity                         = optional(number, 3)<br/>    enable_propagate_additional_user_context_data = optional(bool, false)<br/>    id_token_validity                             = optional(number)<br/>    refresh_token_validity                        = optional(number)<br/>    prevent_user_existence_errors                 = optional(string)<br/>    enable_token_revocation                       = optional(bool, true)<br/>  }))</pre> | `[]` | no |
| <a name="input_attribute_names"></a> [attribute\_names](#input\_attribute\_names) | Compatibility list of simple string schema attributes. Used to derive string\_schemas when string\_schemas is empty. | `list(string)` | <pre>[<br/>  "acr",<br/>  "amr",<br/>  "email",<br/>  "idassurancelevel",<br/>  "nhsid_nrbac_roles",<br/>  "bcss_username",<br/>  "sid",<br/>  "uid"<br/>]</pre> | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region used for derived Cognito hosted UI outputs. | `string` | `"eu-west-2"` | no |
| <a name="input_bootstrap_users"></a> [bootstrap\_users](#input\_bootstrap\_users) | Optional list of bootstrap Cognito users to create. This covers the current BCSS stack pattern where initial training or shared users are provisioned during stack deployment. | <pre>list(object({<br/>    uuid               = string<br/>    bcss_username      = string<br/>    id_assurance_level = string<br/>    rbac_role          = string<br/>    user_password      = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "project": null,<br/>  "regex_replace_chars": null,<br/>  "region": null,<br/>  "service": null,<br/>  "stack": null,<br/>  "tags": {},<br/>  "terraform_source": null,<br/>  "workspace": null<br/>}</pre> | no |
| <a name="input_create"></a> [create](#input\_create) | Determines whether Cognito resources will be created. | `bool` | `true` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Deletion protection setting for the user pool. Valid values are ACTIVE and INACTIVE. | `string` | `"INACTIVE"` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Optional Cognito user pool domain prefix. Defaults to name\_prefix or the resolved user pool name. | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment identifier used by the shared tags module. | `string` | `null` | no |
| <a name="input_message_action"></a> [message\_action](#input\_message\_action) | Message action for bootstrap Cognito user creation. Defaults to SUPPRESS to match the current BCSS stacks. | `string` | `"SUPPRESS"` | no |
| <a name="input_mfa_configuration"></a> [mfa\_configuration](#input\_mfa\_configuration) | MFA setting for the user pool. Valid values are ON, OFF, or OPTIONAL. | `string` | `"OFF"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name identifier used by the shared tags module. | `string` | `null` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Compatibility alias for older callers. Used as the default user pool and domain prefix when user\_pool\_name or domain are unset. | `string` | `null` | no |
| <a name="input_project"></a> [project](#input\_project) | Project identifier used by the shared tags module. | `string` | `null` | no |
| <a name="input_service"></a> [service](#input\_service) | Service identifier used by the shared tags module. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags merged with any tags supplied through the context object. | `map(string)` | `{}` | no |
| <a name="input_terraform_source"></a> [terraform\_source](#input\_terraform\_source) | Source location to record in the Terraform\_source tag. Defaults to the caller module path when not set. | `string` | `null` | no |
| <a name="input_user_email"></a> [user\_email](#input\_user\_email) | Email attribute applied to bootstrap Cognito users. | `string` | `"nhsdigital.axe@nhs.net"` | no |
| <a name="input_user_password"></a> [user\_password](#input\_user\_password) | Fallback password for bootstrap Cognito users when an individual bootstrap\_users entry does not provide user\_password. | `string` | `"changeme"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_app_client_ids"></a> [app\_client\_ids](#output\_app\_client\_ids) | Map of shared-resources app client names to client IDs. |
| <a name="output_app_client_secrets"></a> [app\_client\_secrets](#output\_app\_client\_secrets) | Map of shared-resources app client names to client secrets. |
| <a name="output_client_ids"></a> [client\_ids](#output\_client\_ids) | IDs of any Cognito user pool clients created by this module. |
| <a name="output_client_ids_map"></a> [client\_ids\_map](#output\_client\_ids\_map) | Map of Cognito client names to client IDs. |
| <a name="output_client_secrets"></a> [client\_secrets](#output\_client\_secrets) | Secrets of any Cognito user pool clients created by this module. |
| <a name="output_client_secrets_map"></a> [client\_secrets\_map](#output\_client\_secrets\_map) | Map of Cognito client names to client secrets. |
| <a name="output_secrets_manager_random_passsword_arn"></a> [secrets\_manager\_random\_passsword\_arn](#output\_secrets\_manager\_random\_passsword\_arn) | Deprecated compatibility output from the bespoke BS-Select bootstrap-user flow. This wrapper does not create a bootstrap user secret. |
| <a name="output_user_pool_arn"></a> [user\_pool\_arn](#output\_user\_pool\_arn) | ARN of the Cognito user pool. |
| <a name="output_user_pool_domain_prefix"></a> [user\_pool\_domain\_prefix](#output\_user\_pool\_domain\_prefix) | Configured Cognito domain value. |
| <a name="output_user_pool_endpoint"></a> [user\_pool\_endpoint](#output\_user\_pool\_endpoint) | Cognito user pool endpoint. |
| <a name="output_user_pool_hosted_ui_url"></a> [user\_pool\_hosted\_ui\_url](#output\_user\_pool\_hosted\_ui\_url) | Hosted UI URL for the Cognito domain when a default domain prefix is configured. |
| <a name="output_user_pool_id"></a> [user\_pool\_id](#output\_user\_pool\_id) | ID of the Cognito user pool. |
| <a name="output_user_pool_name"></a> [user\_pool\_name](#output\_user\_pool\_name) | Name of the Cognito user pool. |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
