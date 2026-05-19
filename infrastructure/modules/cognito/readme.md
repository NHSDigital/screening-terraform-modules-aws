# Cognito

## Summary

This is a OAuth2 client that allows us to log into the BS-Select application using the
same controls and security that CIS2 offers. We have the ability to control the configuration
of the client, including the users available for logging in.

## Useful Values

The Cognito client when created will be accessible via the following url:

- <https://bs-select.auth.eu-west-2.amazoncognito.com/>

```java
The following values are needed by the BS-Select application to connect to this Cognito instance:
|Value|Default Profile Value|Description|
|-----|---------------------|-----------|
|spring.security.oauth2.client.registration.nhs-identity.scope|email, openid, profile, aws.cognito.signin.user.admin|The scope used by OAuth2 for the users.|
|spring.security.oauth2.client.registration.nhs-identity.client-id|COGNITO_CLIENT_ID_TO_BE_REPLACED|The client ID for the Cognito user client instance.|
|spring.security.oauth2.client.registration.nhs-identity.client-secret|COGNITO_CLIENT_SECRET_TO_BE_REPLACED|The client secret for the Cognito user client instance.|
|spring.security.oauth2.client.registration.nhs-identity.redirect-uri|https://<environment>/bss/login/oauth2/code/nhs-identity|The redirect once authentication has been completed.|
|spring.security.oauth2.client.provider.nhs-identity.issuer-uri|<https://cognito-idp.eu-west-2.amazonaws.com/COGNITO_ISSUER_URI_TO_BE_REPLACED/>|The issuer-uri, the full URL is required but main value required is the ID of the Cognito user pool|
| spring.security.oauth2.client.provider.nhs-identity.cognito-domain |<https://bs-select.auth.eu-west-2.amazoncognito.com/>|The domain to direct to for login.|
```

## Creating users

Users for this Cognito client are managed via the users.csv file. The following values need to be
specified:

| Column             | Value                                                                                                                                                                                                |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| UUID               | The UUID associated with the user in the BS-Select database. If the user is not in the BS-Select database for the environment, login will fail.                                                      |
| bss_username       | The BS-Select username associated with the user and the value used for the Username value in Cognito.                                                                                                |
| rbac_role          | This replicates the roles CIS2 would provide by using a subset of the data provided. Use the following as the default value for a valid user: `"[{activities=[BS-Select], activity_codes=[B1808]}]"` |
| id_assurance_level | This replicates the assurance level that CIS2 would provide for the user.                                                                                                                            |

When running the nonprod-shared infrastructure pipeline, all the users listed in the CSV file will be created (or modified if a change is made) and
will be automatically marked as being valid. All users are created with the same default password specified in the variables.tf file.

<!-- vale off -->
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.43.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.8.1 |

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
<!-- vale on -->
