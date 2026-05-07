locals {

  defaults = {
    label_order         = ["service", "project", "environment", "stack", "name", "attributes"]
    regex_replace_chars = "/[^-a-zA-Z0-9]/"
    delimiter           = "-"
    replacement         = ""
    id_length_limit     = 0
    id_hash_length      = 5
    label_key_case      = "title"
    label_value_case    = "lower"
  }

  default_labels_as_tags = keys(local.tags_context)

  context_labels_as_tags_is_unset = try(contains(var.context.labels_as_tags, "unset"), true)

  # Do not to allow overriding replacement or id_hash_length
  replacement    = local.defaults.replacement
  id_hash_length = local.defaults.id_hash_length


  # The values provided by variables supersede the values inherited from the context object,
  # except for tags and attributes which are merged.
  input = {
    # It would be nice to use coalesce here, but we cannot, because it
    # is an error for all the arguments to coalesce to be empty.
    enabled     = var.enabled == null ? var.context.enabled : var.enabled
    service     = var.service == null ? var.context.service : var.service
    project     = var.project == null ? var.context.project : var.project
    region      = var.region == null ? lookup(local.to_short, data.aws_region.current.region, null) : var.region
    environment = var.environment == null ? var.context.environment : var.environment
    stack       = var.stack == null ? var.context.stack : var.stack
    name        = var.name == null ? var.context.name : var.name
    workspace   = var.workspace == null ? terraform.workspace : var.workspace
    delimiter   = var.delimiter == null ? var.context.delimiter : var.delimiter
    # modules tack on attributes (passed by var) to the end of the list (passed by context)
    attributes = compact(distinct(concat(coalesce(var.context.attributes, []), coalesce(var.attributes, []))))
    tags       = merge(var.context.tags, var.tags)

    additional_tag_map  = merge(var.context.additional_tag_map, var.additional_tag_map)
    label_order         = var.label_order == null ? var.context.label_order : var.label_order
    regex_replace_chars = var.regex_replace_chars == null ? var.context.regex_replace_chars : var.regex_replace_chars
    id_length_limit     = var.id_length_limit == null ? var.context.id_length_limit : var.id_length_limit
    label_key_case      = var.label_key_case == null ? lookup(var.context, "label_key_case", null) : var.label_key_case
    label_value_case    = var.label_value_case == null ? lookup(var.context, "label_value_case", null) : var.label_value_case

    descriptor_formats = merge(lookup(var.context, "descriptor_formats", {}), var.descriptor_formats)
    labels_as_tags     = local.context_labels_as_tags_is_unset ? var.labels_as_tags : var.context.labels_as_tags
  }

  enabled             = local.input.enabled
  regex_replace_chars = coalesce(local.input.regex_replace_chars, local.defaults.regex_replace_chars)

  # string_label_names are names of inputs that are strings (not list of strings) used as labels
  string_label_names = ["service", "project", "environment", "stack", "name", "workspace", "region"]
  normalized_labels = { for k in local.string_label_names : k =>
    local.input[k] == null ? "" : replace(local.input[k], local.regex_replace_chars, local.replacement)
  }
  normalized_attributes = compact(distinct([for v in local.input.attributes : replace(v, local.regex_replace_chars, local.replacement)]))

  formatted_labels = { for k in local.string_label_names : k => local.label_value_case == "none" ? local.normalized_labels[k] :
    local.label_value_case == "title" ? title(lower(local.normalized_labels[k])) :
    local.label_value_case == "upper" ? upper(local.normalized_labels[k]) : lower(local.normalized_labels[k])
  }

  attributes = compact(distinct([
    for v in local.normalized_attributes : (local.label_value_case == "none" ? v :
      local.label_value_case == "title" ? title(lower(v)) :
    local.label_value_case == "upper" ? upper(v) : lower(v))
  ]))

  service = local.formatted_labels["service"]
  project = local.formatted_labels["project"]

  region      = local.formatted_labels["region"]
  environment = local.formatted_labels["environment"]
  stack       = local.formatted_labels["stack"]
  name        = local.formatted_labels["name"]
  workspace   = local.formatted_labels["workspace"]

  delimiter        = local.input.delimiter == null ? local.defaults.delimiter : local.input.delimiter
  label_order      = local.input.label_order == null ? local.defaults.label_order : coalescelist(local.input.label_order, local.defaults.label_order)
  id_length_limit  = local.input.id_length_limit == null ? local.defaults.id_length_limit : local.input.id_length_limit
  label_key_case   = local.input.label_key_case == null ? local.defaults.label_key_case : local.input.label_key_case
  label_value_case = local.input.label_value_case == null ? local.defaults.label_value_case : local.input.label_value_case

  # labels_as_tags is an exception to the rule that input vars override context values (see above)
  labels_as_tags = contains(local.input.labels_as_tags, "default") ? local.default_labels_as_tags : local.input.labels_as_tags

  # Just for standardization and completeness
  descriptor_formats = local.input.descriptor_formats

  additional_tag_map = merge(var.context.additional_tag_map, var.additional_tag_map)

  tags = merge(local.generated_tags, local.input.tags)

  tags_as_list_of_maps = flatten([
    for key in keys(local.tags) : merge(
      {
        key   = key
        value = local.tags[key]
    }, local.additional_tag_map)
  ])

  tags_context = {
    service     = local.service
    project     = local.project
    region      = local.region
    environment = local.environment
    stack       = local.stack
    workspace   = local.workspace
    # For AWS we need `Name` to be disambiguated since it has a special meaning
    name       = local.id
    attributes = local.id_context.attributes
    # Additional NHS specific tags which may be useful for filtering and auditing, but are not part of the ID and not included in the hash
    # so they do not affect the ID length and do not cause the ID to change when they change. They are included in the tags output and can be used as tags on resources.
    owner               = var.owner
    tag_version         = var.tag_version
    data_classification = var.data_classification
    data_type           = var.data_type
    public_facing       = var.public_facing
    service_category    = var.service_category
    on_off_pattern      = var.on_off_pattern
    application_role    = var.application_role
    terraform_source    = path.module
    deployed_by         = data.aws_iam_session_context.current.arn
    deployed_by_source  = data.aws_iam_session_context.current.issuer_arn
    tool                = var.tool
  }

  generated_tags = {
    for l in setintersection(keys(local.tags_context), local.labels_as_tags) :
    local.label_key_case == "upper" ? upper(l) : (
      local.label_key_case == "lower" ? lower(l) : title(lower(l))
    ) => local.tags_context[l] if length(local.tags_context[l]) > 0
  }

  id_context = {
    service     = local.service
    project     = local.project
    region      = local.region
    environment = local.environment
    stack       = local.stack
    workspace   = local.workspace
    name        = local.name
    attributes  = join(local.delimiter, local.attributes)
  }

  labels = [for l in local.label_order : local.id_context[l] if length(local.id_context[l]) > 0]

  id_full = join(local.delimiter, local.labels)
  # Create a truncated ID if needed
  delimiter_length = length(local.delimiter)
  # Calculate length of normal part of ID, leaving room for delimiter and hash
  id_truncated_length_limit = local.id_length_limit - (local.id_hash_length + local.delimiter_length)
  # Truncate the ID and ensure a single (not double) trailing delimiter
  id_truncated = local.id_truncated_length_limit <= 0 ? "" : "${trimsuffix(substr(local.id_full, 0, local.id_truncated_length_limit), local.delimiter)}${local.delimiter}"
  # Support usages that disallow numeric characters. Would prefer tr 0-9 q-z but Terraform does not support it.
  # Probably would have been better to take the hash of only the characters being removed,
  # so identical removed strings would produce identical hashes, but it is not worth breaking existing IDs for.
  id_hash_plus = "${md5(local.id_full)}qrstuvwxyz"
  id_hash_case = local.label_value_case == "title" ? title(local.id_hash_plus) : local.label_value_case == "upper" ? upper(local.id_hash_plus) : local.label_value_case == "lower" ? lower(local.id_hash_plus) : local.id_hash_plus
  id_hash      = replace(local.id_hash_case, local.regex_replace_chars, local.replacement)
  # Create the short ID by adding a hash to the end of the truncated ID
  id_short = substr("${local.id_truncated}${local.id_hash}", 0, local.id_length_limit)
  id       = local.id_length_limit != 0 && length(local.id_full) > local.id_length_limit ? local.id_short : local.id_full


  # Context of this label to pass to other label modules
  output_context = {
    enabled             = local.enabled
    service             = local.service
    project             = local.project
    region              = local.region
    environment         = local.environment
    stack               = local.stack
    name                = local.name
    delimiter           = local.delimiter
    attributes          = local.attributes
    tags                = local.tags
    additional_tag_map  = local.additional_tag_map
    label_order         = local.label_order
    regex_replace_chars = local.regex_replace_chars
    id_length_limit     = local.id_length_limit
    label_key_case      = local.label_key_case
    label_value_case    = local.label_value_case
    labels_as_tags      = local.labels_as_tags
    descriptor_formats  = local.descriptor_formats
  }

}
