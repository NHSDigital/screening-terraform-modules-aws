# VPC

This module will create an RDS Instance, This instance can then have multiple databases created within it. In the BSS environment we have a single RDS instance and all the developers have databases created within it which are created by github pipelines.

## Preprequisites

In order for this to work you will need to have a VPC running, there is a module defined to deploy a VPC in this repo

## Setup

To use this module simply call it from your Terraform stack, here is an example Terraform file:

```terraform
terraform {
  backend "s3" {
    bucket       = "nhse-bss-cicd-state"
    key          = "terraform-state/rds.tfstate"
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
    }
  }
}

module "rds" {
  source              = "./modules/rds-instance"
  name                = var.name
  environment         = var.environment
  aws_secret_id       = "postgres-credentials"
  rds_instance_class  = "db.r7g.large"
  rds_engine_version  = "17"
  publicly_accessible = true
  ingress_cidr        = var.ingress_cidr
  skip_final_snapshot = true
  name_prefix         = var.name_prefix
  aws_account_id      = var.aws_account_id
}
```

## postgres-credentials

This relies on an aws secret existing called `postgres-credentials` which should contain two key-value pairs, `username` and `password`

## Variables

There are a few key values that need to be passed in:

### name_prefix

The `name_prefix` is the consistant part of the name which will be applied to all resources. In BSS that is `bss-cicd-en` for england and `bss-cicd-ni` for northen ireland. These would usually be passed in via either a tfvar file or via cli from a pipeline, we use github actions in the BSS team.

### name

This is the name of the resource, in BSS we are using `eks` as we have a single eks cluster which is shared by all developers, if you wanted multiple you would need to ensure the name was unique for each stack.

### environment

This is the name of the environment it is deployed into, this might be `CICD`, `NTF`, `UFT` or `Prod`.

### aws_account_id

This is the AWS account number, it should be stored securely and passed in as a secret. in the variables file it is defined as being sensitive so it will not be shown in Terraform output.

### ingress_cidr

Used for security groups to allow external access, helpful for remote developers without requiring a VPN but should be used with care outside of CICD environment.

### Optional variables

There are many other variables which have default values which can be overwritten if desired, you can look in the variables.tf file for the full list which should all have descriptions explaining what they do.
