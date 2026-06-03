locals {
  # Build the subnet_mapping from the firewall subnet IDs provided
  # by the VPC module.
  subnet_mapping = { for idx, subnet_id in var.firewall_subnet_ids :
    "subnet-${idx}" => {
      subnet_id       = subnet_id
      ip_address_type = "IPV4"
    }
  }

  # KMS encryption configuration for the firewall and policy.

  encryption_configuration = var.kms_key_arn != null ? {
    key_id = var.kms_key_arn
    type   = "CUSTOMER_KMS"
  } : null

  # ----------------------------------------------------------------
  # Logging configuration
  # ----------------------------------------------------------------
  alert_log_config = var.create_alert_log ? [{
    log_destination = {
      logGroup = aws_cloudwatch_log_group.alert[0].name
    }
    log_destination_type = "CloudWatchLogs"
    log_type             = "ALERT"
  }] : []

  flow_log_config = var.flow_log_s3_bucket_name != null ? [{
    log_destination = {
      bucketName = var.flow_log_s3_bucket_name
      prefix     = coalesce(var.flow_log_s3_prefix, module.this.id)
    }
    log_destination_type = "S3"
    log_type             = "FLOW"
  }] : []

  logging_config  = concat(local.alert_log_config, local.flow_log_config)
  create_logging  = length(local.logging_config) > 0
}
