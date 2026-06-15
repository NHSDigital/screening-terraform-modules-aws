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

tci_bin=""

if command -v terraform-config-inspect &>/dev/null; then
  tci_bin="$(command -v terraform-config-inspect)"
elif command -v mise &>/dev/null && mise which terraform-config-inspect &>/dev/null; then
  tci_bin="$(mise which terraform-config-inspect)"
elif command -v go &>/dev/null; then
  gopath_tci="$(go env GOPATH 2>/dev/null)/bin/terraform-config-inspect"
  if [[ -x "$gopath_tci" ]]; then
    tci_bin="$gopath_tci"
  fi
fi

if [[ -z "$tci_bin" ]]; then
  echo "ERROR: terraform-config-inspect not found on PATH." >&2
  echo "Install with: go install github.com/hashicorp/terraform-config-inspect@latest" >&2
  echo "If already installed with Go, add \"\$(go env GOPATH)/bin\" to PATH." >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "ERROR: jq not found on PATH." >&2
  exit 1
fi

"$tci_bin" --json . | jq -r '
  [.required_providers[].aliases]
  | flatten
  | del(.[] | select(. == null))
  | reduce .[] as $entry (
    {};
    .provider[$entry.name] //= [] | .provider[$entry.name] += [{"alias": $entry.alias}]
  )
' | tee aliased-providers.tf.json
