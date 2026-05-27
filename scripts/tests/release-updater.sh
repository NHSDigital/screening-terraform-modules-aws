#!/bin/bash

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# Build an isolated fixture so this smoke test never mutates real repo files.
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

mkdir -p "${tmp_dir}/infrastructure/modules/example"

cat > "${tmp_dir}/infrastructure/modules/example/main.tf" <<'EOF'
module "plain" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/tags?ref=2.0.0"
}

module "prefixed" {
  source = "git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/inspector?ref=v2.0.0"
}
EOF

cat > "${tmp_dir}/infrastructure/modules/example/README.md" <<'EOF'
| Name | Source | Version |
| ---- | ------ | ------- |
| this | git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/tags | 2.0.0 |
| this2 | git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/inspector | v2.0.0 |
EOF

# Show the key lines before update for quick local debugging.
echo "Before update:"
grep -nE "source =|\| git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/" \
  "${tmp_dir}/infrastructure/modules/example/main.tf" \
  "${tmp_dir}/infrastructure/modules/example/README.md"

(
  cd "${tmp_dir}"
  node "${OLDPWD}/scripts/release/update-tags-module-version.cjs" 2.0.0 2.1.0
)

# Assertions: both plain and v-prefixed references must be updated.
grep -q "tags?ref=2.1.0" "${tmp_dir}/infrastructure/modules/example/main.tf"
grep -q "inspector?ref=v2.1.0" "${tmp_dir}/infrastructure/modules/example/main.tf"
grep -q "modules/tags | 2.1.0 |" "${tmp_dir}/infrastructure/modules/example/README.md"
grep -q "modules/inspector | v2.1.0 |" "${tmp_dir}/infrastructure/modules/example/README.md"

# Guard against old values remaining in the fixture.
if grep -qE "\?ref=v?2\.0\.0|\|\s*v?2\.0\.0\s*\|" "${tmp_dir}/infrastructure/modules/example/main.tf" "${tmp_dir}/infrastructure/modules/example/README.md"; then
  echo "Smoke test failed: old version references are still present." >&2
  exit 1
fi

echo "After update:"
grep -nE "source =|\| git::https://github.com/NHSDigital/screening-terraform-modules-aws.git//infrastructure/modules/" \
  "${tmp_dir}/infrastructure/modules/example/main.tf" \
  "${tmp_dir}/infrastructure/modules/example/README.md"

echo "release-updater smoke test passed"
