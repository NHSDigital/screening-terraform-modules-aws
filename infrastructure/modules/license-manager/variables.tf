################################################################
# License Manager-specific inputs.
#
# Naming, tagging and the master `enabled` switch come from
# `context.tf` via `module.this` — see that file for the full
# list of inherited inputs (service, project, environment,
# stack, name, owner, data_classification, tags, etc.).
################################################################

variable "name_override" {
  description = "Optional explicit name for the License Manager license configuration. When null, the name is derived from the shared context (`module.this.id`)."
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the License Manager license configuration."
  type        = string
  default     = null
}

variable "license_counting_type" {
  description = "Dimension used to track license inventory. One of: vCPU, Instance, Core, Socket."
  type        = string

  validation {
    condition     = contains(["vCPU", "Instance", "Core", "Socket"], var.license_counting_type)
    error_message = "license_counting_type must be one of vCPU, Instance, Core, Socket."
  }
}

variable "license_count" {
  description = "Number of licenses managed by the configuration. Null means no count is tracked. Note: removing this attribute after creation is not supported by the License Manager API and requires resource replacement."
  type        = number
  default     = null
}

variable "license_count_hard_limit" {
  description = "If true, the `license_count` is enforced as a hard limit (further usage is blocked once exceeded)."
  type        = bool
  default     = false
}

variable "license_rules" {
  description = <<-EOT
    Optional list of License Manager rules in the form `#RuleType=RuleValue`.
    Supported rule types: minimumVcpus, maximumVcpus, minimumCores, maximumCores,
    minimumSockets, maximumSockets, allowedTenancy. Example:
      ["#minimumSockets=2", "#allowedTenancy=EC2-DedicatedHost"]
  EOT
  type        = list(string)
  default     = []
}

################################################################
# Associations
################################################################

variable "associated_resource_arns" {
  description = <<-EOT
    Map of resource ARNs to associate with the license configuration.
    Keys are stable, caller-supplied identifiers (e.g. `windows-ami-2022`)
    used so resources can be added/removed without forcing other
    associations to be re-created. Values are the ARNs of AMIs, EC2
    instances, hosts, or other supported resources.
  EOT
  type        = map(string)
  default     = {}
}
