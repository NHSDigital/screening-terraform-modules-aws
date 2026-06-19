#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/mise/update-tool-versions.sh [--dry-run] [--upgrade-level <all|major|minor|patch>]

Updates project-managed tool versions by:
1) Running mise upgrade against local project tool definitions
2) Synchronising .tool-versions with mise.toml [tools] versions
3) Updating the README prerequisites table
4) Regenerating mise.lock

Options:
  --dry-run                       Show outdated tools only; make no changes
  --upgrade-level <all|major|minor|patch>
                                  Filter upgrades by semantic version delta.
                                  Defaults to all.
EOF
}

DRY_RUN=false
UPGRADE_LEVEL="all"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --upgrade-level)
      if [[ "$#" -lt 2 ]]; then
        echo "Missing value for --upgrade-level" >&2
        usage >&2
        exit 2
      fi
      UPGRADE_LEVEL="$2"
      shift 2
      ;;
    *)
      echo "Unsupported argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ ! "$UPGRADE_LEVEL" =~ ^(all|major|minor|patch)$ ]]; then
  echo "Invalid --upgrade-level value: $UPGRADE_LEVEL" >&2
  usage >&2
  exit 2
fi

if ! command -v mise >/dev/null 2>&1; then
  echo "mise is required but was not found in PATH" >&2
  exit 1
fi

if [[ "$UPGRADE_LEVEL" != "all" ]] && ! command -v jq >/dev/null 2>&1; then
  echo "jq is required when --upgrade-level is set to major/minor/patch" >&2
  exit 1
fi

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
cd "$REPO_ROOT"

classify_semver_delta() {
  local current="$1"
  local latest="$2"
  local curr_maj curr_min curr_pat lat_maj lat_min lat_pat
  local -a match=()

  current="${current#v}"
  latest="${latest#v}"

  if [[ ! "$current" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    echo "non-semver"
    return 0
  fi
  match=("${BASH_REMATCH[@]}")
  curr_maj="${match[1]}"
  curr_min="${match[2]}"
  curr_pat="${match[3]}"

  if [[ ! "$latest" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    echo "non-semver"
    return 0
  fi
  match=("${BASH_REMATCH[@]}")
  lat_maj="${match[1]}"
  lat_min="${match[2]}"
  lat_pat="${match[3]}"

  if (( 10#$lat_maj > 10#$curr_maj )); then
    echo "major"
  elif (( 10#$lat_min > 10#$curr_min )); then
    echo "minor"
  elif (( 10#$lat_pat > 10#$curr_pat )); then
    echo "patch"
  else
    echo "none"
  fi
}

collect_filtered_upgrades_tsv() {
  local level="$1"
  local outdated_json="$2"
  local tool current latest delta

  while IFS=$'\t' read -r tool current latest; do
    delta="$(classify_semver_delta "$current" "$latest")"

    if [[ "$delta" == "non-semver" ]]; then
      echo "Skipping non-semver tool for filtered upgrades: $tool ($current -> $latest)" >&2
      continue
    fi

    if [[ "$delta" == "$level" ]]; then
      printf '%s\t%s\t%s\n' "$tool" "$current" "$latest"
    fi
  done < <(printf '%s\n' "$outdated_json" | jq -r 'to_entries[] | "\(.key)\t\(.value.current // "")\t\(.value.latest // "")"')
}

if [[ "$UPGRADE_LEVEL" == "all" ]]; then
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "Running in dry-run mode"
    mise outdated --local --bump
    exit 0
  fi

  echo "Planned upgrades (all levels):"
  mise outdated --local --bump

  mise install
  mise upgrade --local --bump
else
  outdated_json="$(mise outdated --local --bump --json)"
  mapfile -t filtered_upgrade_rows < <(collect_filtered_upgrades_tsv "$UPGRADE_LEVEL" "$outdated_json")
  tools_to_upgrade=()

  for row in "${filtered_upgrade_rows[@]}"; do
    IFS=$'\t' read -r tool _ _ <<< "$row"
    tools_to_upgrade+=("$tool")
  done

  echo "Planned $UPGRADE_LEVEL upgrades:"
  if [[ "${#filtered_upgrade_rows[@]}" -eq 0 ]]; then
    echo "  - none"
  else
    for row in "${filtered_upgrade_rows[@]}"; do
      IFS=$'\t' read -r tool current latest <<< "$row"
      echo "  - $tool: $current -> $latest"
    done
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "Running in dry-run mode (upgrade-level=$UPGRADE_LEVEL)"
    if [[ "${#tools_to_upgrade[@]}" -eq 0 ]]; then
      echo "No $UPGRADE_LEVEL updates available."
    fi
    exit 0
  fi

  if [[ "${#tools_to_upgrade[@]}" -eq 0 ]]; then
    echo "No $UPGRADE_LEVEL updates available. Nothing to do."
    exit 0
  fi

  mise install
  mise upgrade --local --bump "${tools_to_upgrade[@]}"
fi

sync_tool_versions_from_toml() {
  local toml_file="mise.toml"
  local asdf_file=".tool-versions"
  local tmp_file

  if [[ ! -f "$toml_file" || ! -f "$asdf_file" ]]; then
    echo "Expected files mise.toml and .tool-versions were not found" >&2
    exit 1
  fi

  declare -gA toml_versions=()
  local in_tools=false
  local line key value
  local quoted_key_re='^[[:space:]]*"([^"]+)"[[:space:]]*=[[:space:]]*"([^"]+)"'
  local plain_key_re='^[[:space:]]*([A-Za-z0-9._:-]+)[[:space:]]*=[[:space:]]*"([^"]+)"'

  toml_versions=()

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

sync_readme_prerequisites_from_toml() {
  local readme_file="README.md"
  local tmp_file
  local line
  local in_block=false

  if [[ ! -f "$readme_file" ]]; then
    echo "Expected file README.md was not found" >&2
    exit 1
  fi

  # Tool metadata registry: tool_key -> "display_name|url|purpose|version_prefix"
  # Only tools listed here appear in the generated prerequisites table.
  # Add new entries when introducing a tool that developers must install.
  declare -A tool_metadata=(
    [actionlint]="actionlint|https://github.com/rhysd/actionlint|GitHub Actions linter|"
    [bats]="bats-core|https://github.com/bats-core/bats-core|Bash test framework|"
    [gitleaks]="Gitleaks|https://github.com/gitleaks/gitleaks|Secret scanning|"
    [go:github.com/hashicorp/terraform-config-inspect]="terraform-config-inspect|https://github.com/hashicorp/terraform-config-inspect|Generate aliased providers for validation|"
    [jq]="jq|https://jqlang.github.io/jq/|JSON processor|"
    [make]="GNU make|https://www.gnu.org/software/make/|Task runner|>= "
    [pre-commit]="pre-commit|https://pre-commit.com/|Git hook framework|"
    [shellcheck]="shellcheck|https://www.shellcheck.net/|Shell script linter|"
    [terraform]="Terraform|https://www.terraform.io/|Infrastructure as code|>= "
    [terraform-docs]="terraform-docs|https://terraform-docs.io/|Auto-generate module documentation|"
    [tflint]="tflint|https://github.com/terraform-linters/tflint|Terraform linter|"
    [vale]="Vale|https://vale.sh/|English prose linter|"
    [yq]="yq|https://github.com/mikefarah/yq|YAML processor (Go implementation)|"
  )

  # Build the table rows for tools present in both metadata and toml_versions
  local rows=""
  local key display_name url purpose version_prefix version
  for key in "${!tool_metadata[@]}"; do
    if [[ -z "${toml_versions[$key]:-}" ]]; then
      continue
    fi
    IFS='|' read -r display_name url purpose version_prefix <<< "${tool_metadata[$key]}"
    version="${version_prefix}${toml_versions[$key]}"
    rows+="| [$display_name]($url) | $version | $purpose |"$'\n'
  done

  # Sort rows alphabetically by display name (first column)
  rows="$(printf '%s' "$rows" | sort -t'[' -k2,2 -f)"

  tmp_file="$(mktemp)"

  while IFS= read -r line; do
    if [[ "$line" == "<!-- BEGIN_AUTOGENERATED_PREREQUISITES -->" ]]; then
      in_block=true
      printf '%s\n' "$line" >> "$tmp_file"
      printf '%s\n' "| Tool | Version | Purpose |" >> "$tmp_file"
      printf '%s\n' "| --- | --- | --- |" >> "$tmp_file"
      printf '%s\n' "$rows" >> "$tmp_file"
      continue
    fi

    if [[ "$line" == "<!-- END_AUTOGENERATED_PREREQUISITES -->" ]]; then
      in_block=false
      printf '%s\n' "$line" >> "$tmp_file"
      continue
    fi

    # Skip old content between the markers
    if [[ "$in_block" == "true" ]]; then
      continue
    fi

    printf '%s\n' "$line" >> "$tmp_file"
  done < "$readme_file"

  mv "$tmp_file" "$readme_file"
}

sync_tool_versions_from_toml
sync_readme_prerequisites_from_toml
mise lock

echo "Updated mise.toml, .tool-versions, README.md, and mise.lock"
