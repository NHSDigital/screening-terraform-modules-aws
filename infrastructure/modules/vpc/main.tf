################################################################
# VPC Module
#
# Screening wrapper around the `terraform-aws-modules/vpc/aws`
# community module.
#
#   firewall  – Network Firewall endpoints       (default /28)
#   public    – public-facing resources, NAT GWs  (default /24)
#   private   – workloads with internet via NAT    (default /23)
#   intra     – no internet route                  (default /23)
#
# Naming and tagging are derived from context.tf via module.this.
#
# Cross-variable input constraints are enforced in validations.tf.
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
  intra_subnets   = local.intra_subnets

  # IGW: when Network Firewall routing is enabled, we create the
  # IGW as a standalone resource so that public subnets do NOT get
  # a default route to the IGW (that route goes via the firewall
  # VPCE instead, injected at the stack level).
  create_igw = !var.enable_network_firewall

  # Per-AZ public route tables: required when Network Firewall is
  # enabled so that each AZ's outbound traffic traverses the
  # firewall endpoint in the same AZ (symmetric routing).
  create_multiple_public_route_tables = var.enable_network_firewall

  # NAT gateway configuration
  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = !var.single_nat_gateway

  # DNS
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # DHCP options
  enable_dhcp_options              = var.enable_dhcp_options
  dhcp_options_domain_name         = var.dhcp_options_domain_name
  dhcp_options_domain_name_servers = var.dhcp_options_domain_name_servers
  dhcp_options_ntp_servers         = var.dhcp_options_ntp_servers
  dhcp_options_tags                = var.dhcp_options_tags

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
  intra_subnet_tags   = var.intra_subnet_tags

  # Exclude "Name" — the community module sets its own Name tags on all resources
  tags = { for k, v in module.this.tags : k => v if k != "Name" }
}

################################################################
# Firewall subnets
#
# Created as standalone resources because the upstream module
# does not have a dedicated firewall subnet tier.
################################################################

resource "aws_subnet" "firewall" {
  count = module.this.enabled && var.enable_network_firewall ? local.az_count : 0

  vpc_id            = module.vpc.vpc_id
  cidr_block        = local.firewall_subnets[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(module.this.tags, var.firewall_subnet_tags, {
    Name = "${module.this.id}-firewall-${local.azs[count.index]}"
    Type = "firewall"
  })
}

resource "aws_route_table" "firewall" {
  count = module.this.enabled && var.enable_network_firewall ? local.az_count : 0

  vpc_id = module.vpc.vpc_id

  tags = merge(module.this.tags, {
    Name = "${module.this.id}-firewall-${local.azs[count.index]}"
  })
}

resource "aws_route_table_association" "firewall" {
  count = module.this.enabled && var.enable_network_firewall ? local.az_count : 0

  subnet_id      = aws_subnet.firewall[count.index].id
  route_table_id = aws_route_table.firewall[count.index].id
}

################################################################
# Internet Gateway (Network Firewall routing mode)
#
# When enable_network_firewall = true, the community module's
# IGW is disabled (create_igw = false) so that public subnets
# do NOT get a default route to the IGW. Instead:
#   - The IGW is created here as a standalone resource
#   - Firewall subnets get 0.0.0.0/0 → IGW
#   - Public subnets get 0.0.0.0/0 → firewall VPCE (injected
#     at the stack level)
#
# When enable_network_firewall = false, these resources are not
# created and the community module handles everything.
################################################################

resource "aws_internet_gateway" "this" {
  count = module.this.enabled && var.enable_network_firewall ? 1 : 0

  vpc_id = module.vpc.vpc_id

  tags = merge(module.this.tags, {
    Name = module.this.id
  })
}

resource "aws_route" "firewall_to_igw" {
  count = module.this.enabled && var.enable_network_firewall ? local.az_count : 0

  route_table_id         = aws_route_table.firewall[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

################################################################
# IGW edge route table (Network Firewall mode)
#
# The edge route table is associated with the Internet Gateway.
# It routes return traffic (from the internet) destined for each
# public subnet CIDR through the firewall endpoint in the same
# AZ, ensuring symmetric routing for stateful inspection.
#
# The actual per-CIDR routes are injected at the stack level
# because they depend on the Network Firewall module's VPCE IDs.
################################################################

resource "aws_route_table" "edge" {
  count = module.this.enabled && var.enable_network_firewall ? 1 : 0

  vpc_id = module.vpc.vpc_id

  tags = merge(module.this.tags, {
    Name = "${module.this.id}-edge"
  })
}

resource "aws_route_table_association" "edge" {
  count = module.this.enabled && var.enable_network_firewall ? 1 : 0

  gateway_id     = aws_internet_gateway.this[0].id
  route_table_id = aws_route_table.edge[0].id
}

################################################################
# VPC Flow Logs
#
# Uses the standalone flow-log submodule from
# terraform-aws-modules/vpc/aws (the root module's built-in
# flow log support is deprecated in v6.x, removed in v7.0.0).
#
# The submodule creates:
#   - CloudWatch Log Group
#   - IAM Role with scoped trust policy
#   - VPC Flow Log resource
################################################################

module "flow_log" {
  source  = "terraform-aws-modules/vpc/aws//modules/flow-log"
  version = "6.6.1"

  create = module.this.enabled && var.enable_flow_log

  name   = "${module.this.id}-flow-log"
  vpc_id = module.vpc.vpc_id

  # CloudWatch destination
  log_destination_type                   = "cloud-watch-logs"
  cloudwatch_log_group_name              = "/vpc/${module.this.id}/flow-logs"
  cloudwatch_log_group_use_name_prefix   = false
  cloudwatch_log_group_retention_in_days = var.flow_log_retention_in_days
  cloudwatch_log_group_kms_key_id        = var.flow_log_kms_key_id

  # IAM role (created by the submodule with scoped trust policy)
  create_iam_role          = true
  iam_role_name            = "${module.this.id}-flow-logs"
  iam_role_use_name_prefix = false

  traffic_type             = var.flow_log_traffic_type
  max_aggregation_interval = var.flow_log_max_aggregation_interval

  cloudwatch_log_group_tags = var.cloudwatch_log_group_tags
  flow_log_tags             = var.flow_log_tags
  iam_role_tags             = var.iam_role_tags

  tags = module.this.tags
}
