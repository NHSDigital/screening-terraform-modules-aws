#!/usr/bin/env bash
# Generate an aliased-providers.tf.json file for modules that use
# provider configuration_aliases (Terraform >= 0.15).
#
# Requires: terraform-config-inspect, jq
# Install terraform-config-inspect:
#   go install github.com/hashicorp/terraform-config-inspect@latest
# Or via brew:
#   brew install hashicorp/tap/terraform-config-inspect
#
# See: https://github.com/antonbabenko/pre-commit-terraform#terraform_validate

set -euo pipefail

if ! command -v terraform-config-inspect &>/dev/null; then
  echo "ERROR: terraform-config-inspect not found on PATH." >&2
  echo "Install with: go install github.com/hashicorp/terraform-config-inspect@latest" >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "ERROR: jq not found on PATH." >&2
  exit 1
fi

terraform-config-inspect --json . | jq -r '
  [.required_providers[].aliases]
  | flatten
  | del(.[] | select(. == null))
  | reduce .[] as $entry (
    {};
    .provider[$entry.name] //= [] | .provider[$entry.name] += [{"alias": $entry.alias}]
  )
' | tee aliased-providers.tf.json
