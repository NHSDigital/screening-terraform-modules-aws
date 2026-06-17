#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/mise/update-tool-versions.sh [--dry-run]

Updates project-managed tool versions by:
1) Running mise upgrade against local project tool definitions
2) Synchronising .tool-versions with mise.toml [tools] versions
3) Regenerating mise.lock

Options:
  --dry-run   Show outdated tools only; make no changes
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
elif [[ -n "${1:-}" ]]; then
  echo "Unsupported argument: $1" >&2
  usage >&2
  exit 2
fi

if ! command -v mise >/dev/null 2>&1; then
  echo "mise is required but was not found in PATH" >&2
  exit 1
fi

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
cd "$REPO_ROOT"

if [[ "$DRY_RUN" == "true" ]]; then
  echo "Running in dry-run mode"
  mise outdated --local --bump
  exit 0
fi

mise install
mise upgrade --local --bump

sync_tool_versions_from_toml() {
  local toml_file="mise.toml"
  local asdf_file=".tool-versions"
  local tmp_file

  if [[ ! -f "$toml_file" || ! -f "$asdf_file" ]]; then
    echo "Expected files mise.toml and .tool-versions were not found" >&2
    exit 1
  fi

  declare -A toml_versions=()
  local in_tools=false
  local line key value
  local quoted_key_re='^[[:space:]]*"([^"]+)"[[:space:]]*=[[:space:]]*"([^"]+)"'
  local plain_key_re='^[[:space:]]*([A-Za-z0-9._:-]+)[[:space:]]*=[[:space:]]*"([^"]+)"'

  while IFS= read -r line; do
    if [[ "$line" =~ ^\[tools\]$ ]]; then
      in_tools=true
      continue
    fi

    if [[ "$line" =~ ^\[[^]]+\]$ && "$line" != "[tools]" ]]; then
      in_tools=false
    fi

    if [[ "$in_tools" == "false" ]]; then
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*# ]]; then
      continue
    fi

    if [[ $line =~ $quoted_key_re ]]; then
      key="${BASH_REMATCH[1]}"
      value="${BASH_REMATCH[2]}"
      toml_versions["$key"]="$value"
      continue
    fi

    if [[ $line =~ $plain_key_re ]]; then
      key="${BASH_REMATCH[1]}"
      value="${BASH_REMATCH[2]}"
      toml_versions["$key"]="$value"
    fi
  done < "$toml_file"

  tmp_file="$(mktemp)"

  while IFS= read -r line; do
    if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
      printf '%s\n' "$line" >> "$tmp_file"
      continue
    fi

    key="${line%%[[:space:]]*}"
    if [[ -n "${toml_versions[$key]:-}" ]]; then
      printf '%s %s\n' "$key" "${toml_versions[$key]}" >> "$tmp_file"
    else
      printf '%s\n' "$line" >> "$tmp_file"
    fi
  done < "$asdf_file"

  mv "$tmp_file" "$asdf_file"
}

sync_tool_versions_from_toml
mise lock

echo "Updated mise.toml, .tool-versions, and mise.lock"
