module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.4.0"

  create = module.this.enabled
  name   = module.this.id
  tags   = module.this.tags

  ami                                = var.ami
  ami_ssm_parameter                  = var.ami_ssm_parameter
  associate_public_ip_address        = var.associate_public_ip_address
  availability_zone                  = var.availability_zone
  capacity_reservation_specification = var.capacity_reservation_specification
  cpu_credits                        = var.cpu_credits
  cpu_options                        = var.cpu_options
  create_eip                         = var.create_eip
  create_iam_instance_profile        = var.create_iam_instance_profile
  create_security_group              = var.create_security_group
  create_spot_instance               = var.create_spot_instance
  disable_api_stop                   = var.disable_api_stop
  disable_api_termination            = var.disable_api_termination
  ebs_optimized                      = var.ebs_optimized
  iam_instance_profile               = var.iam_instance_profile
  instance_type                      = var.instance_type
  key_name                           = var.key_name
  metadata_options                   = var.metadata_options
  monitoring                         = true
  root_block_device                  = var.root_block_device
  subnet_id                          = var.subnet_id
  user_data                          = var.user_data
  user_data_replace_on_change        = false
  vpc_security_group_ids             = var.vpc_security_group_ids
}
