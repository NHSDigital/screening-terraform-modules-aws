data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs      = data.aws_availability_zones.available.names
  az_count = length(local.azs)

  # Subnet CIDR allocation from the VPC CIDR (assumes /16)

  auto_firewall_subnets = [for i in range(local.az_count) : cidrsubnet(cidrsubnet(var.vpc_cidr, 8, 0), 4, i)]
  auto_public_subnets   = [for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 8, 16 + i)]
  auto_private_subnets  = [for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 7, 16 + i)]
  auto_isolated_subnets = [for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 7, 24 + i)]

  firewall_subnets = length(var.firewall_subnets) > 0 ? var.firewall_subnets : local.auto_firewall_subnets
  public_subnets   = length(var.public_subnets) > 0 ? var.public_subnets : local.auto_public_subnets
  private_subnets  = length(var.private_subnets) > 0 ? var.private_subnets : local.auto_private_subnets
  isolated_subnets = length(var.isolated_subnets) > 0 ? var.isolated_subnets : local.auto_isolated_subnets
}
