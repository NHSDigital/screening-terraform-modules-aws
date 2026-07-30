################################################################
# VPC
################################################################

output "vpc_id" {
  description = "The ID of the VPC."
  value       = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "The ARN of the VPC."
  value       = module.vpc.vpc_arn
}

output "vpc_cidr_block" {
  description = "The primary CIDR block of the VPC."
  value       = module.vpc.vpc_cidr_block
}

################################################################
# Availability zones
################################################################

output "azs" {
  description = "The availability zones used by this VPC."
  value       = local.azs
}

################################################################
# Public subnets
################################################################

output "public_subnet_ids" {
  description = "List of IDs of the public subnets."
  value       = module.vpc.public_subnets
}

output "public_subnets_cidr_blocks" {
  description = "List of CIDR blocks of the public subnets."
  value       = module.vpc.public_subnets_cidr_blocks
}

output "public_route_table_ids" {
  description = "List of IDs of the public route tables."
  value       = module.vpc.public_route_table_ids
}

################################################################
# Private subnets (NAT-routed)
################################################################

output "private_subnet_ids" {
  description = "List of IDs of the private subnets (routed via NAT)."
  value       = module.vpc.private_subnets
}

output "private_subnets_cidr_blocks" {
  description = "List of CIDR blocks of the private subnets."
  value       = module.vpc.private_subnets_cidr_blocks
}

output "private_route_table_ids" {
  description = "List of IDs of the private route tables."
  value       = module.vpc.private_route_table_ids
}

################################################################
# Intra subnets (no internet)
################################################################

output "intra_subnet_ids" {
  description = "List of IDs of the intra subnets (no internet route)."
  value       = module.vpc.intra_subnets
}

output "intra_subnets_cidr_blocks" {
  description = "List of CIDR blocks of the intra subnets."
  value       = module.vpc.intra_subnets_cidr_blocks
}

output "intra_route_table_ids" {
  description = "List of IDs of the intra route tables."
  value       = module.vpc.intra_route_table_ids
}

################################################################
# Firewall subnets
################################################################

output "firewall_subnet_ids" {
  description = "List of IDs of the firewall subnets."
  value       = aws_subnet.firewall[*].id
}

output "firewall_subnets_cidr_blocks" {
  description = "List of CIDR blocks of the firewall subnets."
  value       = aws_subnet.firewall[*].cidr_block
}

output "firewall_route_table_ids" {
  description = "List of IDs of the firewall route tables."
  value       = aws_route_table.firewall[*].id
}

################################################################
# NAT gateways
################################################################

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs."
  value       = module.vpc.natgw_ids
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for NAT Gateways."
  value       = module.vpc.nat_public_ips
}

################################################################
# Internet gateway
################################################################

output "igw_id" {
  description = "The ID of the Internet Gateway."
  value       = var.enable_network_firewall ? try(aws_internet_gateway.this[0].id, null) : module.vpc.igw_id
}

output "igw_arn" {
  description = "The ARN of the Internet Gateway."
  value       = var.enable_network_firewall ? try(aws_internet_gateway.this[0].arn, null) : module.vpc.igw_arn
}

################################################################
# Default security group
################################################################

output "default_security_group_id" {
  description = "The ID of the default security group."
  value       = module.vpc.default_security_group_id
}

################################################################
# VPC Flow Logs
################################################################

output "flow_log_id" {
  description = "The ID of the VPC Flow Log."
  value       = module.flow_log.id
}

output "flow_log_arn" {
  description = "The ARN of the VPC Flow Log."
  value       = module.flow_log.arn
}

output "flow_log_cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group for VPC flow logs."
  value       = module.flow_log.cloudwatch_log_group_arn
}

output "flow_log_iam_role_arn" {
  description = "The ARN of the IAM role used by VPC flow logs."
  value       = module.flow_log.iam_role_arn
}

################################################################
# Edge route table
################################################################

output "edge_route_table_id" {
  description = "ID of the IGW edge route table (only when enable_network_firewall = true)."
  value       = try(aws_route_table.edge[0].id, null)
}
