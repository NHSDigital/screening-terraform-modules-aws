variable "name_prefix" {
  description = "the prefix for the name which containts the environment and business unit"
  type        = string
}

variable "name" {
  description = "The name of the resource"
  type        = string
  default     = "security-hub"
}

variable "s3_bucket" {
  description = "The s3 bucket that security-hub will use"
  type        = string
}
