# AWS Network Firewall Terraform module

Terraform module to provision an [AWS Network Firewall](https://aws.amazon.com/network-firewall/) integrated with the VPC module's dedicated firewall subnets.

## Usage

```hcl
    module "network_firewall" {
      source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/network-firewall"

      service     = "bcss"
      project     = "bcss"
      environment = "dev"
      stack       = "shared-resources"
      workspace   = terraform.workspace
      name        = "nwfw"

      vpc_id              = module.vpc.vpc_id
      firewall_subnet_ids = module.vpc.firewall_subnet_ids

      # Encryption (optional — from the kms module)
      kms_key_arn          = module.nwfw_kms.key_arn
      alert_log_kms_key_id = module.nwfw_kms.key_arn

      # FLOW logs to S3 (optional — from the s3-bucket module)
      flow_log_s3_bucket_name = module.logs_bucket.s3_bucket_id

      # Policy — rule groups are passed by arn
      policy_stateful_rule_group_reference = {
        deny_domains = {
          priority     = 1
          resource_arn = aws_networkfirewall_rule_group.deny_domains.arn
        }
      }
    }
```

<!-- vale off -->
<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
<!-- markdownlint-restore -->
<!-- vale on -->
