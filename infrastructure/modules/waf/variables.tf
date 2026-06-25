################################################################
# Web ACL
################################################################

variable "description" {
  description = "Friendly description of the WAF web ACL."
  type        = string
  default     = "Managed by Terraform"
}

variable "default_action" {
  description = "Default action for requests that do not match any rule. Valid values are allow or block."
  type        = string
  default     = "allow"

  validation {
    condition     = contains(["allow", "block"], var.default_action)
    error_message = "default_action must be either allow or block."
  }
}

variable "scope" {
  description = "Whether the web ACL is regional or for CloudFront."
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["CLOUDFRONT", "REGIONAL"], var.scope)
    error_message = "scope must be one of CLOUDFRONT or REGIONAL."
  }
}

variable "visibility_config" {
  description = "Visibility configuration for the web ACL. Leave null to use the module default metric name and sampling settings."
  type = object({
    cloudwatch_metrics_enabled = bool
    metric_name                = string
    sampled_requests_enabled   = bool
  })
  default = null
}

variable "association_resource_arns" {
  description = "List of resource ARNs to associate with this web ACL, such as an ALB, API Gateway stage, or AppSync resource."
  type        = list(string)
  default     = []
}

variable "token_domains" {
  description = "Optional list of token domains accepted by AWS WAF for cross-domain token usage."
  type        = list(string)
  default     = null
}

################################################################
# Logging
################################################################

variable "log_destination_configs" {
  description = "Destination ARNs for WAF logging. Create log groups, Firehose streams, or S3 buckets outside this module and pass their ARNs here."
  type        = list(string)
  default     = []
}

variable "logging_filter" {
  description = "Optional WAF logging filter configuration passed directly to the upstream module."
  type = object({
    default_behavior = string
    filter = list(object({
      behavior    = string
      requirement = string
      condition = list(object({
        action_condition = optional(object({
          action = string
        }), null)
        label_name_condition = optional(object({
          label_name = string
        }), null)
      }))
    }))
  })
  default = null
}

variable "redacted_fields" {
  description = "Optional log redaction settings passed directly to the upstream module."
  type = map(object({
    method        = optional(bool, false)
    uri_path      = optional(bool, false)
    query_string  = optional(bool, false)
    single_header = optional(list(string), null)
  }))
  default = {}
}

################################################################
# Custom responses
################################################################

variable "custom_response_body" {
  description = "Custom response bodies that can be referenced by block actions."
  type = map(object({
    content      = string
    content_type = string
  }))
  default = {}
}

variable "default_block_response" {
  description = "HTTP status code to return when default_action is block."
  type        = string
  default     = null
}

variable "default_block_custom_response_body_key" {
  description = "Custom response body key to use when default_action is block."
  type        = string
  default     = null
}

################################################################
# Rule inputs
################################################################

variable "byte_match_statement_rules" {
  description = "Byte match rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type = list(object({
    name     = string
    priority = number
    action   = string
    captcha_config = optional(object({
      immunity_time_property = object({
        immunity_time = number
      })
    }), null)
    rule_label = optional(list(string), null)
    custom_response = optional(object({
      response_code            = string
      custom_response_body_key = optional(string, null)
      response_header = optional(object({
        name  = string
        value = string
      }), null)
    }), null)
    statement = any
    visibility_config = optional(object({
      cloudwatch_metrics_enabled = optional(bool)
      metric_name                = string
      sampled_requests_enabled   = optional(bool)
    }), null)
  }))
  default     = []
}

variable "geo_allowlist_statement_rules" {
  description = "Geo allowlist rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type = list(object({
    name     = string
    priority = number
    action   = string
    captcha_config = optional(object({
      immunity_time_property = object({
        immunity_time = number
      })
    }), null)
    rule_label = optional(list(string), null)
    statement  = any
    visibility_config = optional(object({
      cloudwatch_metrics_enabled = optional(bool)
      metric_name                = string
      sampled_requests_enabled   = optional(bool)
    }), null)
  }))
  default     = []
}

variable "geo_match_statement_rules" {
  description = "Geo match rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type = list(object({
    name     = string
    priority = number
    action   = string
    captcha_config = optional(object({
      immunity_time_property = object({
        immunity_time = number
      })
    }), null)
    rule_label = optional(list(string), null)
    custom_response = optional(object({
      response_code            = string
      custom_response_body_key = optional(string, null)
      response_header = optional(object({
        name  = string
        value = string
      }), null)
    }), null)
    statement = any
    visibility_config = optional(object({
      cloudwatch_metrics_enabled = optional(bool)
      metric_name                = string
      sampled_requests_enabled   = optional(bool)
    }), null)
  }))
  default     = []
}

variable "ip_set_reference_statement_rules" {
  description = "IP set reference rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type = list(object({
    name     = string
    priority = number
    action   = string
    captcha_config = optional(object({
      immunity_time_property = object({
        immunity_time = number
      })
    }), null)
    rule_label = optional(list(string), null)
    custom_response = optional(object({
      response_code            = string
      custom_response_body_key = optional(string, null)
      response_header = optional(object({
        name  = string
        value = string
      }), null)
    }), null)
    statement = any
    visibility_config = optional(object({
      cloudwatch_metrics_enabled = optional(bool)
      metric_name                = string
      sampled_requests_enabled   = optional(bool)
    }), null)
  }))
  default     = []
}

variable "managed_rule_group_statement_rules" {
  description = "Managed rule group rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type = list(object({
    name            = string
    priority        = number
    override_action = optional(string)
    captcha_config = optional(object({
      immunity_time_property = object({
        immunity_time = number
      })
    }), null)
    rule_label = optional(list(string), null)
    statement = object({
      name                             = string
      vendor_name                      = string
      scope_down_not_statement_enabled = optional(bool, false)
      scope_down_statement = optional(object({
        byte_match_statement = object({
          positional_constraint = string
          search_string         = string
          field_to_match = object({
            all_query_arguments   = optional(bool)
            body                  = optional(bool)
            method                = optional(bool)
            query_string          = optional(bool)
            single_header         = optional(object({ name = string }))
            single_query_argument = optional(object({ name = string }))
            uri_path              = optional(bool)
          })
          text_transformation = list(object({
            priority = number
            type     = string
          }))
        })
      }), null)
      version = optional(string)
      rule_action_override = optional(map(object({
        action = string
        custom_request_handling = optional(object({
          insert_header = object({
            name  = string
            value = string
          })
        }), null)
        custom_response = optional(object({
          response_code = string
          response_header = optional(object({
            name  = string
            value = string
          }), null)
        }), null)
      })), null)
      managed_rule_group_configs = optional(list(object({
        aws_managed_rules_anti_ddos_rule_set = optional(object({
          sensitivity_to_block = optional(string)
          client_side_action_config = optional(object({
            challenge = object({
              usage_of_action = string
              sensitivity     = optional(string)
              exempt_uri_regular_expression = optional(list(object({
                regex_string = string
              })))
            })
          }))
        }))
        aws_managed_rules_bot_control_rule_set = optional(object({
          inspection_level        = string
          enable_machine_learning = optional(bool, true)
        }), null)
        aws_managed_rules_atp_rule_set = optional(object({
          enable_regex_in_path = optional(bool)
          login_path           = string
          request_inspection = optional(object({
            payload_type = string
            password_field = object({
              identifier = string
            })
            username_field = object({
              identifier = string
            })
          }), null)
          response_inspection = optional(object({
            body_contains = optional(object({
              success_strings = list(string)
              failure_strings = list(string)
            }), null)
            header = optional(object({
              name           = string
              success_values = list(string)
              failure_values = list(string)
            }), null)
            json = optional(object({
              identifier      = string
              success_strings = list(string)
              failure_strings = list(string)
            }), null)
            status_code = optional(object({
              success_codes = list(string)
              failure_codes = list(string)
            }), null)
          }), null)
        }), null)
        aws_managed_rules_acfp_rule_set = optional(object({
          creation_path          = string
          enable_regex_in_path   = optional(bool)
          registration_page_path = string
          request_inspection = optional(object({
            payload_type = string
            password_field = optional(object({
              identifier = string
            }), null)
            username_field = optional(object({
              identifier = string
            }), null)
            email_field = optional(object({
              identifier = string
            }), null)
            address_fields = optional(object({
              identifiers = list(string)
            }), null)
            phone_number_fields = optional(object({
              identifiers = list(string)
            }), null)
          }), null)
          response_inspection = optional(object({
            body_contains = optional(object({
              success_strings = list(string)
              failure_strings = list(string)
            }), null)
            header = optional(object({
              name           = string
              success_values = list(string)
              failure_values = list(string)
            }), null)
            json = optional(object({
              identifier     = string
              success_values = list(string)
              failure_values = list(string)
            }), null)
            status_code = optional(object({
              success_codes = list(string)
              failure_codes = list(string)
            }), null)
          }), null)
        }))
      })), null)
    })
    visibility_config = optional(object({
      cloudwatch_metrics_enabled = optional(bool)
      metric_name                = string
      sampled_requests_enabled   = optional(bool)
    }), null)
  }))
  default     = []
}

variable "nested_statement_rules" {
  description = "Nested statement rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type = list(object({
    name     = string
    priority = number
    action   = string
    custom_response = optional(object({
      response_code            = string
      custom_response_body_key = optional(string, null)
      response_header = optional(object({
        name  = string
        value = string
      }), null)
    }), null)
    statement = object({
      and_statement = object({
        statements = list(object({
          type      = string
          statement = string
        }))
      })
    })
    visibility_config = optional(object({
      cloudwatch_metrics_enabled = optional(bool)
      metric_name                = string
      sampled_requests_enabled   = optional(bool)
    }), null)
  }))
  default     = []
}

variable "rate_based_statement_rules" {
  description = "Rate-based rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type = list(object({
    name     = string
    priority = number
    action   = string
    captcha_config = optional(object({
      immunity_time_property = object({
        immunity_time = number
      })
    }), null)
    rule_label = optional(list(string), null)
    custom_response = optional(object({
      response_code            = string
      custom_response_body_key = optional(string, null)
      response_header = optional(object({
        name  = string
        value = string
      }), null)
    }), null)
    statement = object({
      limit                 = number
      aggregate_key_type    = string
      evaluation_window_sec = optional(number)
      forwarded_ip_config = optional(object({
        fallback_behavior = string
        header_name       = string
      }), null)
      custom_key = optional(list(object({
        ip = optional(object({}), null)
        header = optional(object({
          name = string
          text_transformation = list(object({
            priority = number
            type     = string
          }))
        }), null)
      })), null)
      scope_down_statement = optional(object({
        byte_match_statement = object({
          positional_constraint = string
          search_string         = string
          field_to_match = object({
            all_query_arguments   = optional(bool)
            body                  = optional(bool)
            method                = optional(bool)
            query_string          = optional(bool)
            single_header         = optional(object({ name = string }))
            single_query_argument = optional(object({ name = string }))
            uri_path              = optional(bool)
          })
          text_transformation = list(object({
            priority = number
            type     = string
          }))
        })
      }), null)
    })
    visibility_config = optional(object({
      cloudwatch_metrics_enabled = optional(bool)
      metric_name                = string
      sampled_requests_enabled   = optional(bool)
    }), null)
  }))
  default     = []
}

variable "regex_match_statement_rules" {
  description = "Regex match rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type = list(object({
    name     = string
    priority = number
    action   = string
    captcha_config = optional(object({
      immunity_time_property = object({
        immunity_time = number
      })
    }), null)
    rule_label = optional(list(string), null)
    statement  = any
    visibility_config = optional(object({
      cloudwatch_metrics_enabled = optional(bool)
      metric_name                = string
      sampled_requests_enabled   = optional(bool)
    }), null)
  }))
  default     = []
}

variable "regex_pattern_set_reference_statement_rules" {
  description = "Regex pattern set reference rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type = list(object({
    name     = string
    priority = number
    action   = string
    captcha_config = optional(object({
      immunity_time_property = object({
        immunity_time = number
      })
    }), null)
    rule_label = optional(list(string), null)
    statement  = any
    visibility_config = optional(object({
      cloudwatch_metrics_enabled = optional(bool)
      metric_name                = string
      sampled_requests_enabled   = optional(bool)
    }), null)
  }))
  default     = []
}

variable "rule_group_reference_statement_rules" {
  description = "Rule group reference rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type = list(object({
    name            = string
    priority        = number
    override_action = optional(string)
    captcha_config = optional(object({
      immunity_time_property = object({
        immunity_time = number
      })
    }), null)
    rule_label = optional(list(string), null)
    statement = object({
      arn = string
      rule_action_override = optional(map(object({
        action = string
        custom_request_handling = optional(object({
          insert_header = object({
            name  = string
            value = string
          })
        }), null)
        custom_response = optional(object({
          response_code = string
          response_header = optional(object({
            name  = string
            value = string
          }), null)
        }), null)
      })), null)
    })
    visibility_config = optional(object({
      cloudwatch_metrics_enabled = optional(bool)
      metric_name                = string
      sampled_requests_enabled   = optional(bool)
    }), null)
  }))
  default     = []
}

variable "size_constraint_statement_rules" {
  description = "Size constraint rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type = list(object({
    name     = string
    priority = number
    action   = string
    captcha_config = optional(object({
      immunity_time_property = object({
        immunity_time = number
      })
    }), null)
    rule_label = optional(list(string), null)
    custom_response = optional(object({
      response_code            = string
      custom_response_body_key = optional(string, null)
      response_header = optional(object({
        name  = string
        value = string
      }), null)
    }), null)
    statement = any
    visibility_config = optional(object({
      cloudwatch_metrics_enabled = optional(bool)
      metric_name                = string
      sampled_requests_enabled   = optional(bool)
    }), null)
  }))
  default     = []
}

variable "sqli_match_statement_rules" {
  description = "SQL injection match rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type = list(object({
    name     = string
    priority = number
    action   = string
    captcha_config = optional(object({
      immunity_time_property = object({
        immunity_time = number
      })
    }), null)
    rule_label = optional(list(string), null)
    statement  = any
    visibility_config = optional(object({
      cloudwatch_metrics_enabled = optional(bool)
      metric_name                = string
      sampled_requests_enabled   = optional(bool)
    }), null)
  }))
  default     = []
}

variable "xss_match_statement_rules" {
  description = "Cross-site scripting match rules passed directly to the upstream module. Consumers must ensure rule priorities are unique across all rule lists."
  type = list(object({
    name     = string
    priority = number
    action   = string
    captcha_config = optional(object({
      immunity_time_property = object({
        immunity_time = number
      })
    }), null)
    rule_label = optional(list(string), null)
    statement  = any
    visibility_config = optional(object({
      cloudwatch_metrics_enabled = optional(bool)
      metric_name                = string
      sampled_requests_enabled   = optional(bool)
    }), null)
  }))
  default     = []
}