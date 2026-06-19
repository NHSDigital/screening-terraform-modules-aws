#!/usr/bin/env bash

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
lock_platforms=(
  linux_arm64
  linux_amd64
  darwin_arm64
  darwin_amd64
  windows_amd64
)

temporary_files=()

cleanup() {
  for path in "${temporary_files[@]:-}"; do
    if [[ -n "$path" && ( -e "$path" || -L "$path" ) ]]; then
      rm -f "$path"
    fi
  done

  return 0
}

trap cleanup EXIT

usage() {
  cat <<EOF
Usage:
  $(basename "$0") <module-path>
  $(basename "$0") update-all

Examples:
  $(basename "$0") infrastructure/modules/vpc
  $(basename "$0") update-all
EOF
}

require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "ERROR: $command_name is required but was not found on PATH." >&2
    exit 1
  fi
}

normalise_module_path() {
  local module_path="$1"

  if [[ "$module_path" == "$repo_root"/* ]]; then
    printf '%s\n' "${module_path#${repo_root}/}"
  else
    printf '%s\n' "${module_path#./}"
  fi
}

find_docs_file() {
  local module_dir="$1"

  if [[ -f "$module_dir/README.md" ]]; then
    printf '%s\n' README.md
    return 0
  fi

  if [[ -f "$module_dir/readme.md" ]]; then
    printf '%s\n' readme.md
    return 0
  fi

  return 1
}

run_terraform_init() {
  local module_path="$1"

  terraform -chdir="$module_path" init -upgrade
}

run_terraform_providers_lock() {
  local module_path="$1"
  local -a args=()

  for platform in "${lock_platforms[@]}"; do
    args+=("-platform=$platform")
  done

  terraform -chdir="$module_path" providers lock "${args[@]}"
}

run_terraform_docs() {
  local module_path="$1"
  local docs_file
  local docs_path
  local symlink_path

  docs_file="$(find_docs_file "$module_path")"
  docs_path="$module_path/$docs_file"

  if [[ "$docs_file" == "readme.md" ]]; then
    symlink_path="$module_path/README.md"
    ln -s "readme.md" "$symlink_path"
    temporary_files+=("$symlink_path")
    docs_path="$symlink_path"
  fi

  pre-commit run terraform_docs --files "$docs_path"
}

run_module() {
  local module_path="$1"

  if [[ ! -d "$repo_root/$module_path" ]]; then
    echo "ERROR: module path does not exist: $module_path" >&2
    exit 1
  fi

  if ! find_docs_file "$repo_root/$module_path" >/dev/null 2>&1; then
    echo "ERROR: no README.md or readme.md found in $module_path" >&2
    exit 1
  fi

  echo "Updating $module_path"
  run_terraform_init "$module_path"
  run_terraform_providers_lock "$module_path"
  run_terraform_docs "$module_path"
}

discover_module_paths() {
  find "$repo_root/infrastructure/modules" \
    -type f \
    -name '*.tf' \
    ! -name 'aliased-providers.tf' \
    ! -path '*/.terraform/*' \
    -print0 |
    while IFS= read -r -d '' file_path; do
      local module_dir
      module_dir="$(dirname "$file_path")"
      printf '%s\n' "${module_dir#${repo_root}/}"
    done |
    sort -u
}

confirm_update_all() {
  echo "WARNING: this will update every Terraform module under infrastructure/modules."
  echo "It may take some time."
  read -r -p "Continue? [y/N] " response

  case "$response" in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      echo "Aborted."
      exit 1
      ;;
  esac
}

main() {
  cd "$repo_root"

  require_command terraform
  require_command pre-commit

  if [[ $# -ne 1 ]]; then
    usage >&2
    exit 1
  fi

  if [[ "$1" == "update-all" ]]; then
    confirm_update_all

    module_paths=()
    while IFS= read -r _path; do
      module_paths+=("$_path")
    done < <(discover_module_paths)

    if [[ ${#module_paths[@]} -eq 0 ]]; then
      echo "ERROR: no Terraform modules were found under infrastructure/modules." >&2
      exit 1
    fi

    for module_path in "${module_paths[@]}"; do
      run_module "$module_path"
    done

    return 0
  fi

  run_module "$(normalise_module_path "$1")"
}

main "$@"
