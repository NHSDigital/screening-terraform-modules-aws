variable "rds_engine_version" {
  type        = string
  description = "The engine version for the RDS instance"
  default     = "12.5"
}

variable "name_prefix" {
  description = "The account, environment etc"
  type        = string
}
variable "users" {
  description = "List of usernames to generate passwords and secrets for"
  type        = list(string)
  default     = ["pi_4_user", "bss_user", "bss_readwrite", "bss_readonly", "audit_user", "release_manager"]
}

variable "recovery_window" {
  description = "The number of days that credentials should be retained for"
  type        = number
}

variable "secret_replication_regions" {
  description = "List of additional regions where created secrets should be replicated"
  type        = list(string)
  default     = []
}

variable "rds_endpoint" {
  description = "The endpoint to connect to the rds instance"
  type        = string
}

variable "rds_password" {
  description = "the password to login to rds with"
  type        = string
  sensitive   = true
}
