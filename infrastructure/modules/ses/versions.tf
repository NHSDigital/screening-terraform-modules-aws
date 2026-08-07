terraform {
  required_version = ">= 1.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.42"
    }
    # TODO: The cloudposse/ses/aws upstream module declares awsutils as a required provider.
    # In practice, awsutils is only used for SMTP password generation (which we hardcode off),
    # so this dependency may be removable if the module is ever rewritten using native AWS
    # resources (aws_ses_domain_identity, aws_ses_domain_dkim, aws_route53_record, etc.).
    awsutils = {
      source  = "cloudposse/awsutils"
      version = ">= 0.11.0"
    }
  }
}
