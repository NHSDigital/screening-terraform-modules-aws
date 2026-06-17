variable "node_type" {
  description = "Node instance type for ElastiCache replication group nodes."
  type        = string
}

variable "engine_version" {
  description = "The Elasticache engine version"
  type        = string
}

variable "auto_failover_enabled" {
  description = "Whether automatic failover is enabled for the replication group."
  type        = bool
}

variable "number_of_shards" {
  description = "Number of shard groups in the replication group."
  type        = number
  default     = 1
}

variable "replicas_per_node_group" {
  description = "Number of replicas per shard group."
  type        = number
  default     = 2
}

variable "replication_group_description" {
  description = "Description for replication group"
  type        = string
  default     = "Redis cache for BS-Select application"
}

# tflint-ignore: terraform_unused_declarations
variable "multi_az" {
  description = "Legacy toggle retained for backwards compatibility."
  type        = bool
}

variable "elasticache_port" {
  description = "Port on which Elasticache runs"
  type        = number
  default     = 6379
}

variable "apply_immediately" {
  description = "whether to apply changes immediately - false will apply in maintenance window"
  type        = bool
  default     = false
}

variable "redis_auth_token" {
  description = "Auth token for Redis cache"
  type        = string
  sensitive   = true
}

variable "notification_topic_arn" {
  description = "Name of the SNS topic used for Elasticache alerts"
  type        = string
}

variable "name_prefix" {
  description = "the prefix for the name which containts the environment and business unit"
  type        = string
}

variable "name" {
  description = "The name of the resource"
  type        = string
  default     = "elasticache"
}

# tflint-ignore: terraform_unused_declarations
variable "environment" {
  description = "The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD"
  type        = string
}

# tflint-ignore: terraform_unused_declarations
variable "aws_account_id" {
  description = "The AWS account ID"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "The ID for the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "The subnets that will be used for elasticache, usually private"
  type        = list(string)
}

variable "ecs_sg_id" {
  description = "The id of the ECS security group to enable access for"
  type        = string
}

variable "create_elasticache_service_role" {
  description = "The service role can only be created once per account, only enable it in one stack"
  type        = bool
  default     = true
}
