# This gets the aws account details so we can fetch the account ID
data "aws_caller_identity" "current" {}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["${var.name_prefix}${var.name}"]
  }
}

# Get public subnets
data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
  filter {
    name   = "tag:kubernetes.io/role/elb"
    values = ["1"]
  }
}
# Get private subnets
data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
  filter {
    name   = "tag:kubernetes.io/role/internal-elb"
    values = ["1"]
  }
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = var.name_prefix
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = data.aws_vpc.vpc.id
  subnet_ids               = data.aws_subnets.private_subnets.ids
  control_plane_subnet_ids = data.aws_subnets.public_subnets.ids

  # Fargate Profile
  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "default"
        }
      ]
      tags = {
        Environment = var.environment
      }
      security_group_ids = [aws_security_group.fargate_ingress.id]
    }
    kube-system = {
      name = "kube-system"
      selectors = [
        {
          namespace = "kube-system"
        }
      ]
      tags = {
        Environment = var.environment
      }
      security_group_ids = [aws_security_group.fargate_ingress.id]
    }
  }

  # Cluster access entry
  enable_cluster_creator_admin_permissions = true
  authentication_mode                      = "API_AND_CONFIG_MAP"

}

resource "aws_eks_access_entry" "admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::${var.account_id}:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_Admin_443e66bf1656dcb5"
}
resource "aws_eks_access_policy_association" "admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::${var.account_id}:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_Admin_443e66bf1656dcb5"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_entry" "user" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::${var.account_id}:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_PowerUser_daddc08250323b7f"
}
resource "aws_eks_access_policy_association" "user_cluster" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::${var.account_id}:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_PowerUser_daddc08250323b7f"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  access_scope {
    type = "cluster"
  }
}
resource "aws_eks_access_policy_association" "user_namespace" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::${var.account_id}:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_PowerUser_daddc08250323b7f"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
  access_scope {
    type       = "namespace"
    namespaces = ["default", "ancl11", "stma7"]
  }
}

resource "aws_security_group" "fargate_ingress" {
  name        = "${var.name}-fargate-ingress"
  description = "Allow inbound http traffic"
  vpc_id      = data.aws_vpc.vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = -1
    to_port     = -1
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

