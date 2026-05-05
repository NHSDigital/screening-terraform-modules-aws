####################################################################################
# BSS COMMON
####################################################################################
variable "name_prefix" {
  description = "The account, environment etc"
  type        = string
}

variable "image_name" {
  description = "The image name for the ECS task"
  type        = string
  default     = "public.ecr.aws/docker/library/busybox:stable"
}

variable "vpc_id" {
  description = "id of the vpc"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "rds_sg_id" {
  description = "The security group ID of the RDS instance"
  type        = string
}

variable "aws_account_id" {
  description = "The aws account id"
  type        = string
}

variable "ecs_cluster_name" {
  description = "The ECS cluster name"
  type        = string
}

variable "replica_task_count" {
  description = "The number of task replicas to run"
  type        = number
  default     = 1
}
