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
# Isolated subnets (no internet)
################################################################

output "isolated_subnet_ids" {
  description = "List of IDs of the fully isolated subnets (no internet route)."
  value       = module.vpc.intra_subnets
}

output "isolated_subnets_cidr_blocks" {
  description = "List of CIDR blocks of the isolated subnets."
  value       = module.vpc.intra_subnets_cidr_blocks
}

output "isolated_route_table_ids" {
  description = "List of IDs of the isolated route tables."
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
  value       = module.vpc.igw_id
}

################################################################
# Default security group
################################################################

output "default_security_group_id" {
  description = "The ID of the default security group."
  value       = module.vpc.default_security_group_id
}
