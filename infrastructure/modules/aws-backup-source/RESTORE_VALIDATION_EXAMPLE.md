# Example: Enable RDS Restore Testing with Automated Validation

This example shows how to enable automated validation of restored RDS instances during AWS Backup restore testing.

## Overview

When AWS Backup performs automated restore testing (configured via `aws_backup_restore_testing_plan`), this feature automatically validates the restored database to ensure it's accessible and contains expected data.

## Configuration

### Basic Setup (No Database Connectivity Testing)

```hcl
module "source" {
  source = "../../modules/aws-backup-source"

  # ... other configuration ...

  backup_plan_config_rds = {
    enable                    = true
    selection_tag             = "NHSE-Enable-Backup"
    validation_window_hours   = 1
    compliance_resource_types = ["RDS"]
    restore_testing_overrides = {
      dbSubnetGroupName    = "my-rds-subnet-group"
      dbParameterGroupName = "my-db-parameter-group"
    }
  }

  # Enable restore validation
  restore_validation_enable = true
}
```

This will validate:

- RDS instance is in "available" state
- Instance configuration matches expectations
- Instance is accessible via API

### Advanced Setup (With Database Connectivity Testing)

For more comprehensive validation including actual database connectivity and structure checks:

```hcl
# First, create a secret with database credentials
resource "aws_secretsmanager_secret" "db_validation_credentials" {
  name = "${var.name_prefix}-restore-validation-credentials"
}

resource "aws_secretsmanager_secret_version" "db_validation_credentials" {
  secret_id = aws_secretsmanager_secret.db_validation_credentials.id
  secret_string = jsonencode({
    username = "validation_user"
    password = "secure_password"  # Use a secure method to generate/store this
    database = "postgres"
    port     = 5432
  })
}

# Create security group for Lambda to access RDS
resource "aws_security_group" "restore_validation_lambda" {
  name        = "${var.name_prefix}-restore-validation-lambda"
  description = "Security group for restore validation Lambda"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  # Adjust to your RDS subnet CIDR
  }
}

# Allow Lambda security group to access RDS
resource "aws_security_group_rule" "rds_allow_validation_lambda" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = var.rds_security_group_id  # Your RDS security group
  source_security_group_id = aws_security_group.restore_validation_lambda.id
}

# Configure backup module with full validation
module "source" {
  source = "../../modules/aws-backup-source"

  # ... other configuration ...

  backup_plan_config_rds = {
    enable                    = true
    selection_tag             = "NHSE-Enable-Backup"
    validation_window_hours   = 2  # Give more time for thorough validation
    compliance_resource_types = ["RDS"]
    restore_testing_overrides = {
      dbSubnetGroupName    = "my-rds-subnet-group"
      dbParameterGroupName = "my-db-parameter-group"
    }
  }

  # Enable restore validation with connectivity testing
  restore_validation_enable                      = true
  restore_validation_db_credentials_secret_name  = aws_secretsmanager_secret.db_validation_credentials.name
  restore_validation_db_credentials_secret_arn   = aws_secretsmanager_secret.db_validation_credentials.arn
  restore_validation_expected_subnet_pattern     = "rds-private-postgres"
  restore_validation_timeout_seconds             = 600
  restore_validation_log_retention_days          = 14

  # VPC configuration for Lambda to access RDS in private subnets
  restore_validation_vpc_config = {
    subnet_ids         = var.lambda_subnet_ids  # Private subnets with NAT gateway
    security_group_ids = [aws_security_group.restore_validation_lambda.id]
  }
}
```

## Validation Checks Performed

### 1. Instance Availability Check

- Verifies the restored RDS instance exists
- Checks that instance status is "available"
- Retrieves endpoint information

### 2. Instance Configuration Check

- Validates DB subnet group matches expected pattern
- Verifies engine type and version
- Checks instance is in correct VPC

### 3. Database Connectivity Check (if credentials provided)

- Attempts to connect to the database
- Executes a simple query (`SELECT version()`)
- Verifies connection can be established

### 4. Database Structure Check (if credentials provided)

- Counts tables in the database
- Checks database size
- Verifies schema structure exists

## Monitoring Validation Results

### CloudWatch Logs

Validation results are logged to CloudWatch:

```text
/aws/lambda/{name_prefix}-backup-restore-validation
```

### Example Log Output

```json
{
  "restore_job_id": "12345678-1234-1234-1234-123456789012",
  "db_instance_id": "restored-db-instance-2024-01-15",
  "validation_results": {
    "instance_available": {
      "passed": true,
      "message": "Instance status: available"
    },
    "instance_configuration": {
      "passed": true,
      "message": "Configuration verified"
    },
    "database_connectivity": {
      "passed": true,
      "message": "Connection successful"
    },
    "database_structure": {
      "passed": true,
      "message": "Found 25 tables"
    }
  },
  "overall_status": "PASSED"
}
```

### CloudWatch Alarms

Create alarms to notify on validation failures:

```hcl
resource "aws_cloudwatch_log_metric_filter" "restore_validation_failures" {
  name           = "${var.name_prefix}-restore-validation-failures"
  log_group_name = "/aws/lambda/${var.name_prefix}-backup-restore-validation"
  pattern        = "{ $.overall_status = \"FAILED\" }"

  metric_transformation {
    name      = "RestoreValidationFailures"
    namespace = "BackupRestoreTesting"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "restore_validation_failures" {
  alarm_name          = "${var.name_prefix}-restore-validation-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RestoreValidationFailures"
  namespace           = "BackupRestoreTesting"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alert when restore validation fails"
  alarm_actions       = [var.sns_topic_arn]
}
```

## Troubleshooting

### Lambda Cannot Connect to RDS

- Verify Lambda is in correct subnets with NAT gateway access
- Check security group rules allow Lambda → RDS on port 5432
- Confirm restored instance uses expected subnet group

### Credentials Not Working

- Verify secret exists and contains correct format
- Check Lambda has permission to read the secret
- Ensure credentials have read access to the database

### Validation Times Out

- Increase `restore_validation_timeout_seconds`
- Check VPC configuration for network issues
- Review Lambda logs for specific errors

## Cost Considerations

- **Lambda invocations**: Once per restore test (typically weekly)
- **Lambda duration**: ~30-60 seconds per validation
- **CloudWatch Logs**: Minimal storage (~1MB per month)
- **VPC**: Data transfer charges apply if Lambda is in VPC

Estimated monthly cost: **< $1 USD** for weekly testing

## Security Best Practices

1. **Use dedicated validation credentials** with read-only access
2. **Rotate credentials regularly** via Secrets Manager
3. **Restrict Lambda iam role** to minimum required permissions
4. **Use VPC endpoints** for Secrets Manager to avoid internet traffic
5. **Enable CloudWatch Logs encryption** in production
6. **Set appropriate log retention** (14-30 days recommended)
