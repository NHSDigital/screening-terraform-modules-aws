variable "node_type" {}

variable "engine_version" {
  description = "The Elasticache engine version"
}

variable "auto_failover_enabled" {}

variable "number_of_shards" {
  default = 1
}

variable "replicas_per_node_group" {
  default = 2
}

variable "replication_group_description" {
  description = "Description for replication group"
  default     = "Redis cache for BS-Select application"
}

variable "multi_az" {}

variable "elasticache_port" {
  description = "Port on which Elasticache runs"
  default     = 6379
}

variable "apply_immediately" {
  description = "whether to apply changes immediately - false will apply in maintenance window"
  default     = false
}

variable "redis_auth_token" {
  description = "Auth token for Redis cache"
  sensitive   = true
}

variable "notification_topic_arn" {
  description = "Name of the SNS topic used for Elasticache alerts"
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

variable "environment" {
  description = "The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD"
  type        = string
}

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
