# tflint-ignore-file: terraform_standard_module_structure, terraform_unused_declarations
#
# ONLY EDIT THIS FILE IN github.com/NHSDigital/screening-terraform-modules-aws/infrastructure/modules/tags
# All other instances of this file should be a copy of that one
#
#
# Copy this file from https://github.com/NHSDigital/screening-terraform-modules-aws/blob/master/infrastructure/modules/tags/exports/context.tf
# and then place it in your Terraform module to automatically get
# tag module standard configuration inputs suitable for passing
# to other modules.
#
# curl -sL https://raw.githubusercontent.com/NHSDigital/screening-terraform-modules-aws/master/infrastructure/modules/tags/exports/context.tf -o context.tf
#
# Modules should access the whole context as `module.this.context`
# to get the input variables with nulls for defaults,
# for example `context = module.this.context`,
# and access individual variables as `module.this.<var>`,
# with final values filled in.
#
# For example, when using defaults, `module.this.context.delimiter`
# will be null, and `module.this.delimiter` will be `-` (hyphen).
#

module "this" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/tags?ref=v2.6.0"

  enabled             = coalesce(var.enabled, lookup(var.context, "enabled", true))
  service             = coalesce(var.service, lookup(var.context, "service", null))
  project             = coalesce(var.project, lookup(var.context, "project", null))
  region              = lookup(var.context, "region", null)
  environment         = coalesce(var.environment, lookup(var.context, "environment", null))
  stack               = lookup(var.context, "stack", null)
  workspace           = lookup(var.context, "workspace", null)
  name                = coalesce(var.name, lookup(var.context, "name", null))
  delimiter           = lookup(var.context, "delimiter", null)
  attributes          = lookup(var.context, "attributes", [])
  tags                = merge(lookup(var.context, "tags", {}), var.tags)
  additional_tag_map  = lookup(var.context, "additional_tag_map", {})
  label_order         = lookup(var.context, "label_order", [])
  regex_replace_chars = lookup(var.context, "regex_replace_chars", null)
  id_length_limit     = lookup(var.context, "id_length_limit", null)
  label_key_case      = lookup(var.context, "label_key_case", null)
  label_value_case    = lookup(var.context, "label_value_case", null)
  terraform_source    = coalesce(var.terraform_source, lookup(var.context, "terraform_source", null), path.module)
  descriptor_formats  = lookup(var.context, "descriptor_formats", {})
  labels_as_tags      = toset(lookup(var.context, "labels_as_tags", ["unset"]))

  context = var.context
}

variable "aws_region" {
  type        = string
  description = "AWS region used for derived Cognito hosted UI outputs."
  default     = "eu-west-2"

  validation {
    condition     = contains(["eu-west-1", "eu-west-2", "us-east-1"], var.aws_region)
    error_message = "AWS Region must be one of eu-west-1, eu-west-2, us-east-1"
  }
}

variable "context" {
  type = any
  default = {
    enabled             = true
    service             = null
    project             = null
    region              = null
    environment         = null
    stack               = null
    workspace           = null
    name                = null
    delimiter           = null
    attributes          = []
    tags                = {}
    additional_tag_map  = {}
    regex_replace_chars = null
    label_order         = []
    id_length_limit     = null
    label_key_case      = null
    label_value_case    = null
    terraform_source    = null
    descriptor_formats  = {}
    labels_as_tags      = ["unset"]
  }
  description = <<-EOT
    Single object for setting entire context at once.
    See description of individual variables for details.
    Leave string and numeric variables as `null` to use default value.
    Individual variable settings (non-null) override settings in context object,
    except for attributes, tags, and additional_tag_map, which are merged.
  EOT

  validation {
    condition     = lookup(var.context, "label_key_case", null) == null ? true : contains(["lower", "title", "upper"], var.context["label_key_case"])
    error_message = "Allowed values: `lower`, `title`, `upper`."
  }

  validation {
    condition     = lookup(var.context, "label_value_case", null) == null ? true : contains(["lower", "title", "upper", "none"], var.context["label_value_case"])
    error_message = "Allowed values: `lower`, `title`, `upper`, `none`."
  }
}

variable "terraform_source" {
  type        = string
  default     = null
  description = "Source location to record in the Terraform_source tag. Defaults to the caller module path when not set."
}

variable "enabled" {
  type        = bool
  default     = null
  description = "Set to false to prevent the module from creating any resources."
}

variable "service" {
  type        = string
  default     = null
  description = "Service identifier used by the shared tags module."
}

variable "project" {
  type        = string
  default     = null
  description = "Project identifier used by the shared tags module."
}

variable "environment" {
  type        = string
  default     = null
  description = "Environment identifier used by the shared tags module."
}

variable "name" {
  type        = string
  default     = null
  description = "Name identifier used by the shared tags module."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags merged with any tags supplied through the context object."
}
