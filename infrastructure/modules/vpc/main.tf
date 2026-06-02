################################################################
# VPC Module
#
# Screening wrapper
# `terraform-aws-modules/vpc/aws` module
#   /28  firewall  – Network Firewall endpoints
#   /24  public    – public-facing resources, NAT gateways
#   /23  private   – private workloads with internet via NAT
#   /23  isolated  – fully isolated, no internet route
#
# Naming and tagging are derived from context.tf via module.this.
################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  create_vpc = module.this.enabled

  name = module.this.id
  cidr = var.vpc_cidr

  azs             = local.azs
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets
  intra_subnets   = local.isolated_subnets

  # NAT gateway configuration
  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = !var.single_nat_gateway

  # DNS
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # Public subnets
  map_public_ip_on_launch = var.map_public_ip_on_launch

  # Security defaults
  manage_default_security_group  = var.manage_default_security_group
  default_security_group_ingress = []
  default_security_group_egress  = []

  manage_default_network_acl = var.manage_default_network_acl
  manage_default_route_table = true

  # Subnet tags
  public_subnet_tags  = var.public_subnet_tags
  private_subnet_tags = var.private_subnet_tags
  intra_subnet_tags   = var.isolated_subnet_tags

  tags = module.this.tags
}

################################################################
# Firewall subnets
#
# Created as standalone resources because the upstream module
# does not have a dedicated firewall subnet tier.
################################################################

resource "aws_subnet" "firewall" {
  count = module.this.enabled ? local.az_count : 0

  vpc_id            = module.vpc.vpc_id
  cidr_block        = local.firewall_subnets[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(module.this.tags, var.firewall_subnet_tags, {
    Name = "${module.this.id}-firewall-${local.azs[count.index]}"
    Type = "firewall"
  })
}

resource "aws_route_table" "firewall" {
  count = module.this.enabled ? local.az_count : 0

  vpc_id = module.vpc.vpc_id

  tags = merge(module.this.tags, {
    Name = "${module.this.id}-firewall-${local.azs[count.index]}"
  })
}

resource "aws_route_table_association" "firewall" {
  count = module.this.enabled ? local.az_count : 0

  subnet_id      = aws_subnet.firewall[count.index].id
  route_table_id = aws_route_table.firewall[count.index].id
}
