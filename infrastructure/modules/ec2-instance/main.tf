module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.4.0"

  create = module.this.enabled
  name   = module.this.id
  tags   = module.this.tags

  ami                     = DAVEH
  instance_type           = DAVEH
  key_name                = DAVEH
  disable_api_termination = DAVEH
  ebs_optimized           = DAVEH
  monitoring              = true
  subnet_id               = DAVEH

  vpc_security_group_ids = DAVEH

  iam_instance_profile = DAVEH

  # root_block_device {
  #   encrypted   = true
  #   kms_key_id  = data.terraform_remote_state.shared_resources.outputs.oracle_ebs_snapshot_kms_key_arn
  #   volume_size = var.oracle19_root_volume_size
  #   volume_type = "gp3"
  # }

  # metadata_options {
  #   http_tokens                 = "required"
  #   http_endpoint               = "enabled"
  #   http_put_response_hop_limit = 1
  #   instance_metadata_tags      = "disabled"
  # }

  user_data                   = DAVEH
  user_data_replace_on_change = false

  # lifecycle {
  #   ignore_changes = [user_data]
  # }

  # DAVEH
}
