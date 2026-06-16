plugin "terraform" {
  enabled = true
  # The recommended preset includes the following rules:
  # - terraform_deprecated_interpolation
  # - terraform_deprecated_index
  # - terraform_unused_declarations
  # - terraform_comment_syntax
  # - terraform_documented_outputs
  # - terraform_documented_variables
  # - terraform_typed_variables
  # - terraform_module_pinned_source
  # - terraform_naming_convention
  # - terraform_required_version
  # - terraform_required_providers
  # - terraform_standard_module_structure
  # - terraform_workspace_remote
  # See https://github.com/terraform-linters/tflint-ruleset-terraform/blob/main/docs/rules/README.md
  preset  = "recommended"
}

# plugin "aws" {
#   enabled = true
#   version = "0.47.0"
#   source  = "github.com/terraform-linters/tflint-ruleset-aws"
# }

config {
  # The local module is used to call local modules in the current repository.
  call_module_type = "local"
  # The all call both local and remote modules, which is useful for loading the default ruleset and the AWS plugin.
  # See https://github.com/terraform-linters/tflint/blob/master/docs/user-guide/calling-modules.md
  # module = all
  # The following configuration is used to ignore specific modules that are not compatible with the AWS plugin.
  # See https://github.com/terraform-linters/tflint/blob/master/docs/user-guide/calling-modules.md
  ignore_module = {}
}

rule "terraform_comment_syntax" {
  enabled = true
  }
rule "terraform_documented_outputs" {
  enabled = true
  }
rule "terraform_documented_variables" {
  enabled = true
  }
rule "terraform_naming_convention" {
  enabled = true
  }
rule "terraform_standard_module_structure" {
  enabled = true
  }

# Below rules are disbaled in favour of the rules in the recommended preset, which are more comprehensive and cover more cases.
# rule "terraform_deprecated_interpolation" {
#   enabled = true
#   }
# rule "terraform_deprecated_index" {
#   enabled = true
#   }
# rule "terraform_unused_declarations" {
#   enabled = true
#   }
# rule "terraform_comment_syntax" {
#   enabled = true
#   }
# rule "terraform_documented_outputs" {
#   enabled = true
#   }
# rule "terraform_documented_variables" {
#   enabled = true
#   }
# rule "terraform_typed_variables" {
#   enabled = true
#   }
# rule "terraform_module_pinned_source" {
#   enabled = true
#   }
# rule "terraform_naming_convention" {
#   enabled = true
#   }
# rule "terraform_required_version" {
#   enabled = true
#   }
# rule "terraform_required_providers" {
#   enabled = true
#   }
# rule "terraform_standard_module_structure" {
#   enabled = true
#   }
# rule "terraform_workspace_remote" {
#   enabled = true
#   }
