#!/usr/bin/env bash
# DEPRECATED: This test file has been replaced by test-module-upgrade.bats
# which uses the bats-core test framework. Run: bats tests/test-module-upgrade.bats

set -euo pipefail

SCRIPT="scripts/terraform/upgrade-module.sh"
FAILED=0
PASSED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

repo_root="$(git rev-parse --show-toplevel)"
fixture_root="$(mktemp -d "$repo_root/tmp/upgrade-module-test.XXXXXX")"
relative_fixture_root="${fixture_root#"${repo_root}"/}"
bin_root="$(mktemp -d)"
log_file="$fixture_root/calls.log"

# shellcheck disable=SC2329 # Invoked via trap on script exit.
cleanup() {
  rm -rf "$fixture_root" "$bin_root"
}

trap cleanup EXIT

cat > "$bin_root/terraform" <<EOF
#!/usr/bin/env bash
printf '%s\n' "terraform:\$*" >> "$log_file"
exit 0
EOF

cat > "$bin_root/pre-commit" <<EOF
#!/usr/bin/env bash
printf '%s\n' "pre-commit:\$*" >> "$log_file"
exit 0
EOF

chmod +x "$bin_root/terraform" "$bin_root/pre-commit"

mkdir -p "$fixture_root/infrastructure/modules/example-one"
mkdir -p "$fixture_root/infrastructure/modules/example-two"

cat > "$fixture_root/infrastructure/modules/example-one/main.tf" <<'EOF'
terraform {
  required_version = ">= 1.13"
}
EOF

cat > "$fixture_root/infrastructure/modules/example-one/README.md" <<'EOF'
# Example one
EOF

cat > "$fixture_root/infrastructure/modules/example-two/main.tf" <<'EOF'
terraform {
  required_version = ">= 1.13"
}
EOF

cat > "$fixture_root/infrastructure/modules/example-two/readme.md" <<'EOF'
# Example two
EOF

assert_contains() {
  local needle="$1"
  local description="$2"

  printf "%-72s ... " "$description"

  if grep -Fq "$needle" "$log_file"; then
    PASSED=$((PASSED + 1))
    printf "%b\n" "${GREEN}✓${NC}"
  else
    FAILED=$((FAILED + 1))
    printf "%b\n" "${RED}✗${NC}"
  fi
}

assert_order() {
  local first="$1"
  local second="$2"
  local description="$3"

  printf "%-72s ... " "$description"

  local first_line second_line
  first_line="$(grep -nF "$first" "$log_file" | head -1 | cut -d: -f1 || true)"
  second_line="$(grep -nF "$second" "$log_file" | head -1 | cut -d: -f1 || true)"

  if [[ -n "$first_line" && -n "$second_line" && "$first_line" -lt "$second_line" ]]; then
    PASSED=$((PASSED + 1))
    printf "%b\n" "${GREEN}✓${NC}"
  else
    FAILED=$((FAILED + 1))
    printf "%b\n" "${RED}✗${NC}"
  fi
}

echo "======================================================================"
echo "Testing Terraform module upgrade helper"
echo "======================================================================"
echo

PATH="$bin_root:$PATH" bash "$repo_root/$SCRIPT" "$fixture_root/infrastructure/modules/example-one"

assert_contains "terraform:-chdir=$relative_fixture_root/infrastructure/modules/example-one init -upgrade" "Single-module init uses -upgrade"
assert_contains "terraform:-chdir=$relative_fixture_root/infrastructure/modules/example-one providers lock -platform=linux_arm64 -platform=linux_amd64 -platform=darwin_arm64 -platform=darwin_amd64 -platform=windows_amd64" "Single-module providers lock runs with all target platforms"
assert_contains "pre-commit:run terraform_docs --files $relative_fixture_root/infrastructure/modules/example-one/README.md" "Single-module terraform_docs runs against README.md"

printf '%s\n' '' > "$log_file"

PATH="$bin_root:$PATH" bash "$repo_root/$SCRIPT" update-all <<< 'yes' >/dev/null

assert_contains "terraform:-chdir=infrastructure/modules/api-gateway init -upgrade" "Update-all touches a lowercase-docs module"
assert_contains "terraform:-chdir=infrastructure/modules/license-manager init -upgrade" "Update-all touches an uppercase-docs module"
assert_contains "pre-commit:run terraform_docs --files infrastructure/modules/api-gateway/README.md" "Update-all uses README.md symlink for lowercase docs"
assert_order "terraform:-chdir=infrastructure/modules/api-gateway init -upgrade" "terraform:-chdir=infrastructure/modules/license-manager init -upgrade" "Update-all processes modules sequentially"

echo
echo "======================================================================"
echo "Test Summary"
echo "======================================================================"
printf "Passed: %b\n" "${GREEN}${PASSED}${NC}"
printf "Failed: %b\n" "${RED}${FAILED}${NC}"
printf "Total:  %d\n" $((PASSED + FAILED))
echo

if [ "$FAILED" -eq 0 ]; then
  printf "%b\n" "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  printf "%b\n" "${RED}✗ Some tests failed!${NC}"
  exit 1
fi
