terraform {
  backend "s3" {
    bucket       = "nhse-bss-cicd-state"
    key          = "terraform-state/eks-resources.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-west-2"
  default_tags {
    tags = {
      Environment = var.environment
      Terraform   = "True"
      Stack       = "EKS-RESOURCES"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

locals {
  cluster_name = "${var.name_prefix}${var.name}"
}

data "aws_eks_cluster" "eks" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = local.cluster_name
}

locals {
  ingress_class_param = yamldecode(<<EOF
apiVersion: eks.amazonaws.com/v1
kind: IngressClassParams
metadata:
  name: alb
spec:
  scheme: internet-facing
EOF
  )
}

resource "kubernetes_manifest" "alb_ingress_class_params" {
  manifest = local.ingress_class_param
}

resource "kubernetes_ingress_class" "ingress" {
  metadata {
    name = "alb"
    annotations = {
      "ingressclass.kubernetes.io/is-default-class" = "true"
    }
  }

  spec {
    controller = "eks.amazonaws.com/alb"
    parameters {
      api_group = "eks.amazonaws.com"
      kind      = "IngressClassParams"
      name      = "alb"
    }
  }
}
