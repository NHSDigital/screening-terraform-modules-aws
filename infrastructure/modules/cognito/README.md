# Cognito

## Summary

This is a OAuth2 client that allows us to log into the BS-Select application using the
same controls and security that CIS2 offers.  We have the ability to control the configuration
of the client, including the users available for logging in.

## Useful Values

The Cognito client when created will be accessible via the following URL:

* <https://bs-select.auth.eu-west-2.amazoncognito.com/>

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

Users for this Cognito client are managed via the users.csv file.  The following values need to be
specified:

|Column|Value|
|------|-----|
|UUID|The UUID associated with the user in the BS-Select database. If the user is not in the BS-Select database for the environment, login will fail.|
|bss_username|The BS-Select username associated with the user and the value used for the Username value in Cognito.|
|rbac_role|This replicates the roles CIS2 would provide by using a subset of the data provided. Use the following as the default value for a valid user: `"[{activities=[BS-Select], activity_codes=[B1808]}]"`
|id_assurance_level|This replicates the assurance level that CIS2 would provide for the user.|

When running the nonprod-shared infrastructure pipeline, all the users listed in the CSV file will be created (or modified if a change is made) and
will be automatically marked as being valid. All users are created with the same default password specified in the variables.tf file.
