module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 7.5.0"

  create = module.this.enabled
  name   = module.this.name
  tags   = module.this.tags
}
