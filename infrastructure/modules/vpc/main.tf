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

################################################################
# VPC Flow Logs
#
# Implemented as standalone resources rather than using the
# upstream module's built-in flow log inputs, which are
# deprecated in v6.x and will be removed in v7.0.0.
# See: https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/master/modules/flow-log
#
# Sends flow logs to a dedicated CloudWatch Log Group with an
# IAM role scoped to that log group only.
################################################################

resource "aws_cloudwatch_log_group" "flow_log" {
  count = module.this.enabled && var.enable_flow_log ? 1 : 0

  name              = "/vpc/${module.this.id}-flow-logs"
  retention_in_days = var.flow_log_retention_in_days
  kms_key_id        = var.flow_log_kms_key_id

  tags = module.this.tags
}

resource "aws_iam_role" "flow_log" {
  count = module.this.enabled && var.enable_flow_log ? 1 : 0

  name = "${module.this.id}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = module.this.tags
}

resource "aws_iam_role_policy" "flow_log" {
  count = module.this.enabled && var.enable_flow_log ? 1 : 0

  name = "${module.this.id}-vpc-flow-logs-policy"
  role = aws_iam_role.flow_log[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups"
      ]
      Resource = "${aws_cloudwatch_log_group.flow_log[0].arn}:*"
    }]
  })
}

resource "aws_flow_log" "this" {
  count = module.this.enabled && var.enable_flow_log ? 1 : 0

  vpc_id               = module.vpc.vpc_id
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow_log[0].arn
  iam_role_arn         = aws_iam_role.flow_log[0].arn
  traffic_type         = var.flow_log_traffic_type

  tags = merge(module.this.tags, {
    Name = "${module.this.id}-vpc-flow-log"
  })
}
