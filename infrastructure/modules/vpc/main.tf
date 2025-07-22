# For eks to work with fargate we need to setup both public and private subnets
# The fargate nodes will deploy into the private subnets, any outbound traffic
# Will pass from the private subnets > Nat gateway > Public Subnets > Internet Gateway
# This is a complicated setup but is required to allow external acces to do things like
# pull container images

# Create the VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.name_prefix}"
  }
}

# attach public subnets to vpc
resource "aws_subnet" "public_subnet_a" {
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "eu-west-2a"
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  tags = {
    "Name" = "${var.name_prefix}-public-a"
    "Type" = "public"
    # "kubernetes.io/role/elb"          = "1"
    # "mapPublicIpOnLaunch"             = "TRUE"
    # "kubernetes.io/role/internal-elb" = "1",
    # "karpenter.sh/discovery"          = "${var.name_prefix}-eks"
  }
}

resource "aws_subnet" "public_subnet_b" {
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2b"
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  tags = {
    "Name" = "${var.name_prefix}-public-b"
    "Type" = "public"
    # "kubernetes.io/role/elb"          = "1"
    # "mapPublicIpOnLaunch"             = "TRUE"
    # "kubernetes.io/role/internal-elb" = "1",
    # "karpenter.sh/discovery"          = "${var.name_prefix}-eks"
  }
}

# attach private subnets to vpc
resource "aws_subnet" "private_subnet_a" {
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2a"
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = false
  tags = {
    "Name" = "${var.name_prefix}-private-a"
    "Type" = "private"
    # "kubernetes.io/cluster/${var.name_prefix}-eks" = "shared"
    # "kubernetes.io/role/internal-elb"              = "1",
    # "mapPublicIpOnLaunch"                          = "FALSE"
    # "karpenter.sh/discovery"                       = "${var.name_prefix}"
    # "kubernetes.io/role/cni"                       = "1"
    # "mapPublicIpOnLaunch"                          = "FALSE"
  }
}

resource "aws_subnet" "private_subnet_b" {
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-west-2b"
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = false
  tags = {
    "Name" = "${var.name_prefix}-private-b"
    "Type" = "private"
    # "kubernetes.io/cluster/${var.name_prefix}-eks" = "shared"
    # "kubernetes.io/role/internal-elb"              = "1",
    # "mapPublicIpOnLaunch"                          = "FALSE"
    # "karpenter.sh/discovery"                       = "${var.name_prefix}"
    # "kubernetes.io/role/cni"                       = "1"
    # "mapPublicIpOnLaunch"                          = "FALSE"
  }
}

# Create the internet gateway,
# this will allow traffic from the public subnets out to the internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.name_prefix}"
  }
}

# create a route table so traffic in the public subnets
# can breakout to the internet using the internet gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.name_prefix}"
  }
}

# Create the nat gateways that allow traffic from the private subnets
# To break out into the public subnets
resource "aws_nat_gateway" "nat_gw_a" {
  allocation_id = aws_eip.eip_a.id
  subnet_id     = aws_subnet.public_subnet_a.id
  tags = {
    Name = "${var.name_prefix}"
  }
}

resource "aws_eip" "eip_a" {
  tags = {
    Name = "${var.name_prefix}"
  }
}

resource "aws_nat_gateway" "nat_gw_b" {
  allocation_id = aws_eip.eip_b.id
  subnet_id     = aws_subnet.public_subnet_b.id
  tags = {
    Name = "${var.name_prefix}"
  }
}

resource "aws_eip" "eip_b" {
  tags = {
    Name = "${var.name_prefix}"
  }
}


# create a route table so traffic in the private subnets
# can use the nat gateways
resource "aws_route_table" "private_rt_a" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_a.id
  }
  tags = {
    Name = "${var.name_prefix}"
  }
}

resource "aws_route_table" "private_rt_b" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_b.id
  }
  tags = {
    Name = "${var.name_prefix}"
  }
}


# associate the route tables with the subnets
resource "aws_route_table_association" "private_rta_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_rt_a.id
}

resource "aws_route_table_association" "private_rta_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_rt_b.id
}

resource "aws_route_table_association" "public_rta_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rta_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}
