# EKS Auto Mode

This module will create an eks cluster with auto-mode, this means that the node group will adjust automatically based on the load.

## Preprequisites

In order for this to work you will need to have a VPC running, there is a module defined to deploy a VPC in this repo, you will need to add some tags to get the network functioning correctly, in your public subnets you will need these tags:

```terraform
"kubernetes.io/role/elb"          = "1"
"mapPublicIpOnLaunch"             = "TRUE"
"kubernetes.io/role/internal-elb" = "1",
"karpenter.sh/discovery"          = "${var.name_prefix}-eks"
```

Then in your private subnets you will need these:

```terraform
"kubernetes.io/cluster/${var.name_prefix}-eks" = "shared"
"kubernetes.io/role/internal-elb"              = "1",
"mapPublicIpOnLaunch"                          = "FALSE"
"karpenter.sh/discovery"                       = "${var.name_prefix}-eks"
"kubernetes.io/role/cni"                       = "1"
"mapPublicIpOnLaunch"                          = "FALSE"
```

>**NOTE** Any values with `${var.name_prefix}-${var.name}` should match the name of your cluster

## Setup

To use this module simply call it from your Terraform stack, here is an example Terraform file:

```terraform
terraform {
  backend "s3" {
    bucket       = "nhse-bss-cicd-state"
    key          = "terraform-state/eks.tfstate"
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
      Stack       = "EKS"
    }
  }
}

module "eks" {
  source         = "./modules/eks"
  name           = var.name
  name_prefix    = var.name_prefix
  environment    = var.environment
  aws_account_id = var.aws_account_id
}
```

## Variables

There are a few key values that need to be passed in:

### name_prefix

The `name_prefix` is the consistant part of the name which will be applied to all resources. In BSS that is `bss-cicd-en` for england and `bss-cicd-ni` for northen ireland. These would usually be passed in via either a tfvar file or via cli from a pipeline, we use Github actions in the BSS team.

### name

This is the name of the resource, in BSS we are using `eks` as we have a single eks cluster which is shared by all developers, if you wanted multiple you would need to ensure the name was unique for each stack.

### environment

This is the name of the environment it is deployed into, this might be `CICD`, `NTF`, `UFT` or `Prod`.

### aws_account_id

This is the AWS account number, it should be stored securely and passed in as a secret. in the variables file it is defined as being sensitive so it will not be shown in Terraform output.

### Optional variables

There are many other variables which have default values which can be overwritten if desired, you can look in the variables.tf file for the full list which should all have descriptions explaining what they do.

## Yaml Directory

There is a `yaml` directory which contains some example files

the `ingress.yaml` file will need to be applied for application load balancers to be created automatically

once the ingress has been applied you can apply the `load-balancer-test.yaml` to deploy a test app that should create an application load balancer automatically.
