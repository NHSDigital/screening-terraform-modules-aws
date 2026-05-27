################################################################
# IAM-specific inputs.
#
# Naming, tagging and the master `enabled` switch come from
# `context.tf` via `module.this` — see that file for the full
# list of inherited inputs (service, project, environment,
# stack, name, owner, data_classification, tags, etc.).
################################################################

variable "path" {
  description = "Default IAM path applied to policies and roles when an entry does not override it. Defaults to `/<service>/<project>/` derived from context."
  type        = string
  default     = null

  validation {
    condition     = var.path == null || can(regex("^/.*/$", coalesce(var.path, "/")))
    error_message = "path must start and end with a forward slash, e.g. \"/bcss/\"."
  }
}

variable "policies" {
  description = <<-EOT
    Map of IAM customer-managed policies to create.

    Each key is a logical identifier (e.g. "read-only", "ssm-session") used
    in the rendered policy name. Each value is an object with:

      policy      - (required) IAM policy document JSON
      description - (optional) policy description
      path        - (optional) IAM path; overrides `var.path` / context default

    Example:
      policies = {
        readonly = {
          policy      = data.aws_iam_policy_document.readonly.json
          description = "Read-only access for SSO permission set"
        }
      }
  EOT
  type = map(object({
    policy      = string
    description = optional(string)
    path        = optional(string)
  }))
  default = {}
}

variable "roles" {
  description = <<-EOT
    Map of IAM roles to create.

    Each key is a logical identifier used in the rendered role name. Each
    value is an object with:

      assume_role_policy   - (required) trust policy JSON
      description          - (optional) role description
      path                 - (optional) IAM path; overrides `var.path` / context default
      max_session_duration - (optional) session duration in seconds (3600-43200)
      permissions_boundary - (optional) ARN of a permissions boundary policy
      policy_arns          - (optional) list of existing/managed policy ARNs to attach
      policy_keys          - (optional) list of keys from `var.policies` to attach
      inline_policies      - (optional) map of inline policy name -> JSON document

    Example:
      roles = {
        ec2-bastion = {
          assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
          policy_arns        = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
          policy_keys        = ["readonly"]
        }
      }
  EOT
  type = map(object({
    assume_role_policy   = string
    description          = optional(string)
    path                 = optional(string)
    max_session_duration = optional(number, 3600)
    permissions_boundary = optional(string)
    policy_arns          = optional(list(string), [])
    policy_keys          = optional(list(string), [])
    inline_policies      = optional(map(string), {})
  }))
  default = {}
}
