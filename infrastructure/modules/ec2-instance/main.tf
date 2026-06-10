module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.4.0"

  create = module.this.enabled
  name   = module.this.id
  tags   = module.this.tags

  # DAVEH
}
