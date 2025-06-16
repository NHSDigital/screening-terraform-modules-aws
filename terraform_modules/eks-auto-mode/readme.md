# EKS Auto Mode

This module will create an eks cluster with auto-mode, this means that the node group will adjust automatically based on the load.

## Setup

To use this module simply call it from your terraform stack, here is an example terraform file:

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

The `name_prefix` is the consistant part of the name which will be applied to all resources. In BSS that is `bss-cicd-en` for england and `bss-cicd-ni` for northen ireland. These would usually be passed in via either a tfvar file or via cli from a pipeline, we use github actions in the BSS team.

### name

This is the name of the resource, in BSS we are using `eks` as we have a single eks cluster which is shared by all developers, if you wanted multiple you would need to ensure the name was unique for each stack.

### environment

This is the name of the environment it is deployed into, this might be `CICD`, `NTF`, `UFT` or `Prod`.

### aws_account_id

This is the AWS account number, it should be stored securely and passed in as a secret. in the variables file it is defined as being sensitive so it will not be shown in terraform output.

### Optional variables

There are many other variables which have default values which can be overwritten if desired, you can look in the variables.tf file for the full list which should all have descriptions explaining what they do.

## Yaml Directory

There is a yaml directory which contains some example files

the `ingress.yaml` file will need to be applied for application load balancers to be created automatically

once the ingress has been applied you can apply the `load-balancer-test.yaml` to deploy a test app that should create an application load balancer automatically.


