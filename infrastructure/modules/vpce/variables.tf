variable "name_prefix" {
  description = "the environment and project"
  type        = string
}

variable "vpce_name" {
  description = "The name of the VPCE"
  type        = string
}

variable "hosted_zone_name" {
  description = "Set the hosted zone name if you would like a R53 alias record set up for this VPCE"
  type        = string
}

variable "hosted_zone_id" {
  description = "Set the hosted zone id if you would like a R53 alias record set up for this VPCE"
  type        = string
}

variable "inbound_port" {
  description = "TCP port for which ingress will be allowed to VPCE"
  type        = number
}

variable "outbound_port" {
  description = "TCP port for which egress will be allowed to VPCE"
  type        = number
}

variable "service_name" {
  description = "VPC endpoint service name to connect to"
  type        = string
}

variable "source_sg_id" {
  description = "Optional id of source SG that will be allowed to send traffic to VPCE e.g. RDS SG"
  type        = string
  default     = ""
}

variable "ingress_cidr_range" {
  description = "Optional CIDR range that will be allowed to send traffic to VPCE e.g. the VPC cidr range"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnet ids"
  type        = list(string)
}

# tflint-ignore: terraform_unused_declarations
variable "subnet_azs" {
  description = "AZs of subnets to associate - this must match the subnets of the remote VPC endpoint service e.g. euw2-az2, euw2-az3"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "VPC id"
  type        = string
}
