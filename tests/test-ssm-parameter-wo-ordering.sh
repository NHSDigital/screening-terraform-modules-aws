#!/usr/bin/env bash
set -euo pipefail

module_dir="infrastructure/modules/ssm-parameter-wo"
expected='"[root] aws_ssm_parameter.this (expand)" -> "[root] aws_ssm_parameter.ignore_value (expand)"'
graph="$(mise x -- terraform -chdir="$module_dir" graph -type=plan)"

if ! grep -Fq "$expected" <<<"$graph"; then
  printf 'SSM toggle dependency is missing: %s\n' "$expected" >&2
  exit 1
fi

printf 'SSM ignore_value toggle dependency is present.\n'
