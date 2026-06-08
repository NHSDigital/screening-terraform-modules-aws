# DAVEH

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "~> 7.5.0"

  create = module.this.enabled

  name   = module.this.name
  region = module.this.region
  tags   = module.this.tags
}
