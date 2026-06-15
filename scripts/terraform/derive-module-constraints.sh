#!/usr/bin/env bash
set -euo pipefail

# Derive per-module Terraform/provider minimum constraints from:
# 1) Local module versions.tf (if present)
# 2) Resolved upstream module versions.tf files from .terraform/modules/modules.json
#
# Output: markdown table to stdout.

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
modules_root="$repo_root/infrastructure/modules"

trim() {
  local s="$1"
  s="${s#${s%%[![:space:]]*}}"
  s="${s%${s##*[![:space:]]}}"
  printf '%s' "$s"
}

extract_required_version() {
  local file="$1"
  if [[ -f "$file" ]]; then
    grep -E 'required_version[[:space:]]*=[[:space:]]*"' "$file" | head -1 | cut -d'"' -f2 || true
  fi
}

extract_aws_version() {
  local file="$1"
  if [[ -f "$file" ]]; then
    awk '
      /required_providers[[:space:]]*\{/ {in_req=1}
      in_req && /aws[[:space:]]*=[[:space:]]*\{/ {in_aws=1}
      in_aws && /version[[:space:]]*=[[:space:]]*"/ {
        n = split($0, parts, "\"")
        if (n >= 2) { print parts[2]; exit }
      }
      in_aws && /}/ {in_aws=0}
      in_req && /}/ {in_req=0}
    ' "$file" || true
  fi
}

as_gte_version() {
  local c
  c="$(trim "$1")"
  if [[ "$c" =~ ^\>\=[[:space:]]*([0-9]+(\.[0-9]+){0,2})$ ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
    return
  fi
  if [[ "$c" =~ ^\>[[:space:]]*([0-9]+(\.[0-9]+){0,2})$ ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
    return
  fi
  printf ''
}

max_semver() {
  local current="$1"
  local candidate="$2"

  if [[ -z "$current" ]]; then
    printf '%s' "$candidate"
    return
  fi

  if [[ "$(printf '%s\n%s\n' "$current" "$candidate" | sort -V | tail -1)" == "$candidate" ]]; then
    printf '%s' "$candidate"
  else
    printf '%s' "$current"
  fi
}

printf '| module | local required_version | upstream required_version max | recommended required_version | local aws | upstream aws max | recommended aws | notes |\n'
printf '| --- | --- | --- | --- | --- | --- | --- | --- |\n'

for module_dir in "$modules_root"/*; do
  [[ -d "$module_dir" ]] || continue
  module="$(basename "$module_dir")"

  local_versions="$module_dir/versions.tf"
  local_tf="$(extract_required_version "$local_versions")"
  local_aws="$(extract_aws_version "$local_versions")"

  upstream_tf_max=""
  upstream_aws_max=""
  notes=""

  modules_json="$module_dir/.terraform/modules/modules.json"
  if [[ -f "$modules_json" ]]; then
    while IFS='|' read -r dep_key dep_source dep_dir; do
      [[ -n "$dep_key" ]] || continue
      [[ "$dep_key" == "" || "$dep_key" == "this" ]] && continue
      [[ "$dep_dir" == "." ]] && continue

      dep_versions="$module_dir/$dep_dir/versions.tf"
      [[ -f "$dep_versions" ]] || continue

      dep_tf_constraint="$(extract_required_version "$dep_versions")"
      dep_aws_constraint="$(extract_aws_version "$dep_versions")"

      dep_tf_gte="$(as_gte_version "$dep_tf_constraint")"
      dep_aws_gte="$(as_gte_version "$dep_aws_constraint")"

      if [[ -n "$dep_tf_gte" ]]; then
        upstream_tf_max="$(max_semver "$upstream_tf_max" "$dep_tf_gte")"
      elif [[ -n "$dep_tf_constraint" ]]; then
        notes+="non-gte upstream tf constraint from ${dep_key}; "
      fi

      if [[ -n "$dep_aws_gte" ]]; then
        upstream_aws_max="$(max_semver "$upstream_aws_max" "$dep_aws_gte")"
      elif [[ -n "$dep_aws_constraint" ]]; then
        notes+="non-gte upstream aws constraint from ${dep_key}; "
      fi
    done < <(jq -r '.Modules[] | [.Key, .Source, .Dir] | @tsv' "$modules_json" | awk -F'\t' '{print $1"|"$2"|"$3}')
  fi

  local_tf_gte="$(as_gte_version "$local_tf")"
  local_aws_gte="$(as_gte_version "$local_aws")"

  rec_tf="$local_tf"
  rec_aws="$local_aws"

  if [[ -n "$upstream_tf_max" && -n "$local_tf_gte" ]]; then
    rec_tf=">= $(max_semver "$local_tf_gte" "$upstream_tf_max")"
  elif [[ -n "$upstream_tf_max" && -z "$local_tf" ]]; then
    rec_tf=">= $upstream_tf_max"
  fi

  if [[ -n "$upstream_aws_max" && -n "$local_aws_gte" ]]; then
    rec_aws=">= $(max_semver "$local_aws_gte" "$upstream_aws_max")"
  elif [[ -n "$upstream_aws_max" && -z "$local_aws" ]]; then
    rec_aws=">= $upstream_aws_max"
  fi

  if [[ -z "$local_tf" && -z "$upstream_tf_max" ]]; then
    notes+="no tf constraint discovered; "
  fi
  if [[ -z "$local_aws" && -z "$upstream_aws_max" ]]; then
    notes+="no aws constraint discovered; "
  fi

  notes="$(trim "$notes")"
  notes="${notes%;}"

  printf '| %s | %s | %s | %s | %s | %s | %s | %s |\n' \
    "$module" \
    "${local_tf:-MISSING}" \
    "${upstream_tf_max:-n/a}" \
    "${rec_tf:-MISSING}" \
    "${local_aws:-MISSING}" \
    "${upstream_aws_max:-n/a}" \
    "${rec_aws:-MISSING}" \
    "${notes:-}" \
    | sed 's/|$/ |/'
done
