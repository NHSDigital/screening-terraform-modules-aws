module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "~> 7.5.0"

  create = module.this.enabled

  name   = module.this.name
  region = module.this.region
  tags   = module.this.tags

  capacity_providers = null # DAVEH

  cloudwatch_log_group_class             = null # DAVEH
  cloudwatch_log_group_kms_key_id        = null # DAVEH
  cloudwatch_log_group_name              = null # DAVEH
  cloudwatch_log_group_retention_in_days = 90   # DAVEH
  cloudwatch_log_group_tags              = {}   # DAVEH

  cluster_capacity_providers               = []    # DAVEH
  cluster_capacity_providers_wait_duration = "20s" # DAVEH

  configuration = { "execute_command_configuration" : { "log_configuration" : { "cloud_watch_log_group_name" : "placeholder" } } } # DAVEH

  create_cloudwatch_log_group      = true # DAVEH
  create_infrastructure_iam_role   = true # DAVEH
  create_node_iam_instance_profile = true # DAVEH
  create_security_group            = true # DAVEH
  create_task_exec_iam_role        = true # DAVEH
  create_task_exec_policy          = true # DAVEH

  default_capacity_provider_strategy = {} # DAVEH

  infrastructure_iam_role_description               = null # DAVEH
  infrastructure_iam_role_name                      = null # DAVEH
  infrastructure_iam_role_override_policy_documents = []   # DAVEH
  infrastructure_iam_role_path                      = null # DAVEH
  infrastructure_iam_role_permissions_boundary      = null # DAVEH
  infrastructure_iam_role_source_policy_documents   = []   # DAVEH
  infrastructure_iam_role_statements                = null # DAVEH
  infrastructure_iam_role_tags                      = {}   # DAVEH
  infrastructure_iam_role_use_name_prefix           = true # DAVEH

  node_iam_role_additional_policies       = {}                                    # DAVEH
  node_iam_role_description               = "ECS Managed Instances node IAM role" # DAVEH
  node_iam_role_name                      = null                                  # DAVEH
  node_iam_role_override_policy_documents = []                                    # DAVEH
  node_iam_role_path                      = null                                  # DAVEH
  node_iam_role_permissions_boundary      = null                                  # DAVEH
  node_iam_role_source_policy_documents   = []                                    # DAVEH
  node_iam_role_statements                = null                                  # DAVEH
  node_iam_role_tags                      = {}                                    # DAVEH
  node_iam_role_use_name_prefix           = true                                  # DAVEH

  security_group_description     = null                                                                                                                                                                                                                  # DAVEH
  security_group_egress_rules    = { "all_ipv4" : { "cidr_ipv4" : "0.0.0.0/0", "description" : "Allow all IPv4 traffic", "ip_protocol" : "-1" }, "all_ipv6" : { "cidr_ipv6" : "::/0", "description" : "Allow all IPv6 traffic", "ip_protocol" : "-1" } } # DAVEH
  security_group_ingress_rules   = {}                                                                                                                                                                                                                    # DAVEH
  security_group_name            = null                                                                                                                                                                                                                  # DAVEH
  security_group_tags            = {}                                                                                                                                                                                                                    # DAVEH
  security_group_use_name_prefix = true                                                                                                                                                                                                                  # DAVEH

  service_connect_defaults = null # DAVEH

  setting = [{ "name" : "containerInsights", "value" : "enabled" }] # DAVEH

  task_exec_iam_role_description          = null # DAVEH
  task_exec_iam_role_name                 = null # DAVEH
  task_exec_iam_role_path                 = null # DAVEH
  task_exec_iam_role_permissions_boundary = null # DAVEH
  task_exec_iam_role_policies             = {}   # DAVEH
  task_exec_iam_role_tags                 = {}   # DAVEH
  task_exec_iam_role_use_name_prefix      = true # DAVEH
  task_exec_iam_statements                = null # DAVEH
  task_exec_secret_arns                   = []   # DAVEH
  task_exec_ssm_param_arns                = []   # DAVEH

  vpc_id = null # DAVEH
}
