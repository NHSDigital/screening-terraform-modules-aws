
# Enable Security Hub
resource "aws_securityhub_account" "main" {
  enable_default_standards = true
}

# Optional: Enable specific Security Hub standards
resource "aws_securityhub_standards_subscription" "aws_foundational" {
  standards_arn = "arn:aws:securityhub:eu-west-2::standard/aws-foundational-security"
  depends_on    = [aws_securityhub_account.main]
}

resource "aws_securityhub_standards_subscription" "cis" {
  standards_arn = "arn:aws:securityhub:eu-west-2::standard/cis-aws-foundations-benchmark/v/1.2.0"
  depends_on    = [aws_securityhub_account.main]
}

resource "aws_securityhub_standards_subscription" "pci_dss" {
  standards_arn = "arn:aws:securityhub:eu-west-2::standard/pci-dss/v/3.2.1"
  depends_on    = [aws_securityhub_account.main]
}

# Optional: Enable Config (required for some Security Hub checks)
resource "aws_config_configuration_recorder_status" "main" {
  name       = "${var.name_prefix}-${var.name}"
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}

resource "aws_config_delivery_channel" "main" {
  name           = "${var.name_prefix}-${var.name}"
  s3_bucket_name = var.s3_bucket.bucket
}

resource "aws_config_configuration_recorder" "main" {
  name     = "${var.name_prefix}-${var.name}"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}


# IAM role for AWS Config
resource "aws_iam_role" "config" {
  name = "${var.name_prefix}-${var.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ConfigRole"
}

# Outputs
output "security_hub_arn" {
  description = "The ARN of the Security Hub account"
  value       = aws_securityhub_account.main.arn
}

