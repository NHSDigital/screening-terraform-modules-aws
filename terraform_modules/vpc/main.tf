# configure vpc
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.environment}-${var.name}"
  }
}

# attach public subnet to vpc
resource "aws_subnet" "public_subnet_a" {
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "eu-west-2a"
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  tags = {
    Name                     = "${var.environment}-${var.name}-public-a"
    "kubernetes.io/role/elb" = 1
  }
}

# attach public subnet to vpc
resource "aws_subnet" "public_subnet_b" {
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2b"
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  tags = {
    Name                     = "${var.environment}-${var.name}-public-b"
    "kubernetes.io/role/elb" = 1
  }
}

# attach private subnet to vpc
resource "aws_subnet" "private_subnet_a" {
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2a"
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = false
  tags = {
    Name                              = "${var.environment}-${var.name}-private-a"
    "kubernetes.io/role/internal-elb" = 1
  }
}

# attach private subnet to vpc
resource "aws_subnet" "private_subnet_b" {
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-west-2b"
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = false
  tags = {
    Name                              = "${var.environment}-${var.name}-private-b"
    "kubernetes.io/role/internal-elb" = 1
  }
}

# set the gateway for the vpc
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.environment} ${var.name} Gateway"
  }
}

# set the route table so instances can call out
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.environment} ${var.name} Public Route Table"
  }
}

# set the route table for private subnets
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw_a.id
  }
  tags = {
    Name = "${var.environment} ${var.name} Private Route Table"
  }
}

resource "aws_nat_gateway" "nat_gw_a" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_subnet_a.id
  tags = {
    Name = "${var.environment} ${var.name} NAT GW A"
  }
}

resource "aws_eip" "eip" {
  tags = {
    Name = "${var.environment} ${var.name} EIP"
  }
}

# connect gateway to public subnet
resource "aws_route_table_association" "public_rta_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rta_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

# connect gateway to private subnet
resource "aws_route_table_association" "private_rta_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rta_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_rt.id
}
