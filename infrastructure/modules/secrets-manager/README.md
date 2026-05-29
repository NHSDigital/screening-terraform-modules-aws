# AWS Secrets Manager Terraform module

Thin NHS wrapper around [terraform-aws-modules/secrets-manager/aws](https://registry.terraform.io/modules/terraform-aws-modules/secrets-manager/aws) that enforces the screening platform's baseline controls.

## Hardcoded controls

| Setting | Value | Reason |
|---|---|---|
| `block_public_policy` | `true` | Public access to secrets is never permitted |

## Usage

### Basic secret

```hcl
module "db_credentials" {
  source = "../../modules/secrets-manager"

  context     = module.this.context
  stack       = "database"
  name        = "db-credentials"
  label_order = ["service", "environment", "stack", "name"]

  description             = "RDS database credentials"
  kms_key_id              = module.rds_kms.key_arn
  recovery_window_in_days = 14

  secret_string = jsonencode({
    username = "admin"
    password = var.db_password
  })
}
```

### Secret with a resource policy

```hcl
module "api_key" {
  source = "../../modules/secrets-manager"

  context = module.this.context
  stack   = "api"
  name    = "third-party-api-key"

  description   = "API key for third-party integration"
  secret_string = var.api_key

  create_policy = true
  policy_statements = {
    allow_app_role = {
      sid    = "AllowAppRoleRead"
      effect = "Allow"
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::123456789012:role/my-app-role"]
      }]
      actions   = ["secretsmanager:GetSecretValue"]
      resources = ["*"]
    }
  }
}
```

### Secret with rotation

```hcl
module "rotated_password" {
  source = "../../modules/secrets-manager"

  context = module.this.context
  stack   = "database"
  name    = "rotated-db-password"

  description           = "Auto-rotated database password"
  ignore_secret_changes = true  # let the rotation Lambda manage the value

  enable_rotation     = true
  rotation_lambda_arn = "arn:aws:lambda:eu-west-2:123456789012:function:rotate-db-secret"
  rotation_rules = {
    automatically_after_days = 30
  }
}
```

## Inputs

### Context inputs

See `context.tf` for the full list of context/tagging inputs (`service`, `environment`, `stack`, `name`, `label_order`, etc.).

### Module-specific inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `description` | `string` | `null` | Description of the secret |
| `kms_key_id` | `string` | `null` | KMS key ARN for encryption. Defaults to `aws/secretsmanager` |
| `recovery_window_in_days` | `number` | `30` | Days before permanent deletion. 0 = immediate, or 7–30 |
| `secret_string` | `string` | `null` | The secret value (sensitive). Use `jsonencode()` for structured data |
| `ignore_secret_changes` | `bool` | `false` | Ignore external changes to the secret value (use with rotation) |
| `create_policy` | `bool` | `false` | Whether to attach a resource-based policy |
| `policy_statements` | `map(object)` | `{}` | IAM policy statements for the secret policy |
| `enable_rotation` | `bool` | `false` | Enable automatic rotation |
| `rotation_lambda_arn` | `string` | `""` | ARN of the rotation Lambda |
| `rotation_rules` | `object` | `null` | Rotation schedule configuration |

## Outputs

| Name | Description |
|---|---|
| `secret_arn` | ARN of the secret |
| `secret_id` | ID of the secret (same as ARN) |
| `secret_name` | Name of the secret |
| `secret_version_id` | Unique identifier of the current secret version |
