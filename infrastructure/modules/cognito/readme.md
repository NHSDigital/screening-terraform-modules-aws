# Cognito

## Summary

This is a OAuth2 client that allows us to log into the BS-Select application using the
same controls and security that CIS2 offers. We have the ability to control the configuration
of the client, including the users available for logging in.

# Cognito

Thin wrapper around [`lgallard/cognito-user-pool/aws`](https://registry.terraform.io/modules/lgallard/cognito-user-pool/aws/4.0.2)
for the shared-resources stack.

## Summary

This module standardises Cognito user pool creation around the preferred upstream
community module while adopting this repository's shared `context.tf` pattern.
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

## What this module does not do

* It does not create or replicate a Secrets Manager password secret
* It does not create the KMS keys or SSM parameters used by the older external
	and training stacks; those remain stack-level concerns and can consume this
	module's outputs instead

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

## Intentionally omitted upstream surface

The wrapper does not directly expose the upstream generic inputs for:

* identity providers
* resource servers
* user groups
* arbitrary client definitions beyond the curated `app_clients` OAuth client shape

If those become required later, they can be added back with an explicit shared-resources use case.

## Proven BCSS compatibility notes

Comparing against the current BCSS stacks showed that the module surface needs to cover:

* user pool settings such as deletion protection, MFA, schema attributes, and username settings
* one or more OAuth app clients with callback URLs, logout URLs, token settings, and user-existence handling
* optional bootstrap user creation for shared, external, and training environments

The BCSS stacks also contain stack-specific KMS and SSM parameter resources for some environments.
Those are intentionally not moved into this shared module.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.46.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cognito_user.cognito_user_creation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user) | resource |
| [aws_cognito_user_pool.cognito_user_pool](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool) | resource |
| [aws_cognito_user_pool_domain.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_domain) | resource |
| [aws_secretsmanager_secret.password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_ssm_parameter.cognito_users](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_acr"></a> [acr](#input\_acr) | n/a | `string` | `"AAL1_USERPASS"` | no |
| <a name="input_amr"></a> [amr](#input\_amr) | n/a | `string` | `"USERPASS"` | no |
| <a name="input_attribute_names"></a> [attribute\_names](#input\_attribute\_names) | n/a | `list(string)` | <pre>[<br/>  "acr",<br/>  "amr",<br/>  "email",<br/>  "idassurancelevel",<br/>  "nhsid_nrbac_roles",<br/>  "bss_username",<br/>  "sid",<br/>  "uid"<br/>]</pre> | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | ################################################################################# COGNITO ################################################################################# | `string` | `"INACTIVE"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD | `string` | n/a | yes |
| <a name="input_message_action"></a> [message\_action](#input\_message\_action) | n/a | `string` | `"SUPPRESS"` | no |
| <a name="input_mfa_configuration"></a> [mfa\_configuration](#input\_mfa\_configuration) | n/a | `string` | `"OFF"` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | The account, environment etc | `string` | n/a | yes |
| <a name="input_recovery_window"></a> [recovery\_window](#input\_recovery\_window) | The number of days that credentials should be retained for | `number` | n/a | yes |
| <a name="input_secret_replication_regions"></a> [secret\_replication\_regions](#input\_secret\_replication\_regions) | List of additional regions where created secrets should be replicated | `list(string)` | n/a | yes |
| <a name="input_user_email"></a> [user\_email](#input\_user\_email) | n/a | `string` | `"nhsdigital.axe@nhs.net"` | no |
| <a name="input_user_password"></a> [user\_password](#input\_user\_password) | n/a | `string` | `"changeme"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_secrets_manager_random_passsword_arn"></a> [secrets\_manager\_random\_passsword\_arn](#output\_secrets\_manager\_random\_passsword\_arn) | n/a |
| <a name="output_user_pool_domain_prefix"></a> [user\_pool\_domain\_prefix](#output\_user\_pool\_domain\_prefix) | n/a |
| <a name="output_user_pool_id"></a> [user\_pool\_id](#output\_user\_pool\_id) | n/a |
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->

