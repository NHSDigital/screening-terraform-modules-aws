module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.4.0"

  create = module.this.enabled
  name   = module.this.id
  tags   = module.this.tags

  ami                     = var.ami
  instance_type           = var.instance_type
  key_name                = var.key_name
  disable_api_termination = var.disable_api_termination
  ebs_optimized           = var.ebs_optimized
  monitoring              = true
  subnet_id               = var.subnet_id

  vpc_security_group_ids = var.vpc_security_group_ids

  iam_instance_profile = var.iam_instance_profile

  root_block_device = var.root_block_device

  metadata_options = var.metadata_options

  user_data                   = var.user_data
  user_data_replace_on_change = false

  # DAVEH: can't set lifecycle hooks on module calls, want it set on the
  # underlying resource anyway. vague plan is to fork the module, but
  # not there yet
  # lifecycle {
  #   ignore_changes = [user_data]
  # }
}
