variable "environment" {
  description = "The name of the Environment this is deployed into, for example CICD, NFT, UAT or PROD"
  type        = string
}

variable "bucket_name" {
  description = "The name of the bucket"
  type        = string
}

variable "name_prefix" {
  description = "provides the prefix to keep consistancy"
  type        = string
}

variable "logging_bucket" {
  description = "The bucket where logs are stored for s3 events"
  type        = string
  default     = "logging"
}

variable "bucket_policy" {
  description = "The access policy for the bucket"
  type        = string
}

