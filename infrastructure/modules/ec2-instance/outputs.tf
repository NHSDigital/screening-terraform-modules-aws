output "ami" {
  description = "AMI ID that was used to create the instance"
  value       = module.ec2_instance.ami
}

output "ec2_instance_arn" {
  description = "The ARN of the EC2 instance"
  value       = module.ec2_instance.arn
}

output "availability_zone" {
  description = "The availability zone of the created instance"
  value       = module.ec2_instance.availability_zone
}

output "capacity_reservation_specification" {
  description = "Capacity reservation specification of the instance"
  value       = module.ec2_instance.capacity_reservation_specification
}

output "ebs_block_device" {
  description = "EBS block device information"
  value       = module.ec2_instance.ebs_block_device
}

output "ebs_volumes" {
  description = "Map of EBS volumes created and their attributes"
  value       = module.ec2_instance.ebs_volumes
}

output "ephemeral_block_device" {
  description = "Ephemeral block device information"
  value       = module.ec2_instance.ephemeral_block_device
}

output "iam_instance_profile_arn" {
  description = "ARN assigned by AWS to the instance profile"
  value       = module.ec2_instance.iam_instance_profile_arn
}

output "iam_instance_profile_id" {
  description = "Instance profile's ID"
  value       = module.ec2_instance.iam_instance_profile_id
}

output "iam_instance_profile_unique" {
  description = "Stable and unique string identifying the IAM instance profile"
  value       = module.ec2_instance.iam_instance_profile_unique
}

output "iam_role_arn" {
  description = "The ARN specifying the IAM role"
  value       = module.ec2_instance.iam_role_arn
}

output "iam_role_name" {
  description = "The name of the IAM role"
  value       = module.ec2_instance.iam_role_name
}

output "iam_role_unique_id" {
  description = "Stable and unique string identifying the IAM role"
  value       = module.ec2_instance.iam_role_unique_id
}

output "ec2_instance_id" {
  description = "The ID of the EC2 instance"
  value       = module.ec2_instance.id
}

output "instance_state" {
  description = "The state of the instance"
  value       = module.ec2_instance.instance_state
}

output "ipv6_addresses" {
  description = "The IPv6 address assigned to the instance, if applicable"
  value       = module.ec2_instance.ipv6_addresses
}

output "outpost_arn" {
  description = "The ARN of the Outpost the instance is assigned to"
  value       = module.ec2_instance.outpost_arn
}

output "password_data" {
  description = "Base-64 encoded encrypted password data for the instance. Useful for getting the administrator password for instances running Microsoft Windows. This attribute is only exported if `get_password_data` is true"
  value       = module.ec2_instance.password_data
}

output "primary_network_interface_id" {
  description = "The ID of the instance's primary network interface"
  value       = module.ec2_instance.primary_network_interface_id
}

output "private_dns" {
  description = "The private DNS name assigned to the instance. Can only be used inside the Amazon EC2, and only available if you've enabled DNS hostnames for your VPC"
  value       = module.ec2_instance.private_dns
}

output "private_ip" {
  description = "The private IP address assigned to the instance"
  value       = module.ec2_instance.private_ip
}

output "public_dns" {
  description = "The public DNS name assigned to the instance. For EC2-VPC, this is only available if you've enabled DNS hostnames for your VPC"
  value       = module.ec2_instance.public_dns
}

output "public_ip" {
  description = "The public IP address assigned to the instance, if applicable."
  value       = module.ec2_instance.public_ip
}

output "root_block_device" {
  description = "Root block device information"
  value       = module.ec2_instance.root_block_device
}

output "security_group_arn" {
  description = "The ARN of the security group"
  value       = module.ec2_instance.security_group_arn
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = module.ec2_instance.security_group_id
}

output "spot_bid_status" {
  description = "The current bid status of the Spot Instance Request"
  value       = module.ec2_instance.spot_bid_status
}

output "spot_instance_id" {
  description = "The Instance ID (if any) that is currently fulfilling the Spot Instance request"
  value       = module.ec2_instance.spot_instance_id
}

output "spot_request_state" {
  description = "The current request state of the Spot Instance Request"
  value       = module.ec2_instance.spot_request_state
}

output "tags_all" {
  description = "A map of tags assigned to the resource, including those inherited from the provider default_tags configuration block"
  value       = module.ec2_instance.tags_all
}
