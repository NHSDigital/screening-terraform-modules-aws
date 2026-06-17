#!/usr/bin/env bash

set -euo pipefail

SCRIPT="scripts/mise/update-tool-versions.sh"
FAILED=0
PASSED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

repo_root="$(git rev-parse --show-toplevel)"
mkdir -p "$repo_root/tmp"
fixture_root="$(mktemp -d "$repo_root/tmp/tool-version-upgrade-test.XXXXXX")"
bin_root="$(mktemp -d)"
log_file="$fixture_root/calls.log"

# shellcheck disable=SC2329 # Invoked via trap on script exit.
cleanup() {
  rm -rf "$fixture_root" "$bin_root"
}

trap cleanup EXIT

mkdir -p "$fixture_root"

cat > "$fixture_root/mise.toml" <<'EOF'
[settings]
lockfile = true

[tools]
terraform = "1.13.2"
python = "3.12"
"go:github.com/hashicorp/terraform-config-inspect" = "latest"
EOF

cat > "$fixture_root/.tool-versions" <<'EOF'
terraform 1.13.2
python 3.12
go:github.com/hashicorp/terraform-config-inspect latest
EOF

cat > "$fixture_root/mise.lock" <<'EOF'
# old lock
EOF

cat > "$bin_root/mise" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
log_file="${MISE_TEST_LOG:?}"
repo_root="${REPO_ROOT:?}"

printf '%s\n' "mise:$*" >> "$log_file"

case "$1" in
  outdated)
    echo "terraform 1.13.2 -> 1.13.3"
    ;;
  install)
    ;;
  upgrade)
    cat > "$repo_root/mise.toml" <<'TOML'
[settings]
lockfile = true

[tools]
terraform = "1.13.3"
python = "3.13"
"go:github.com/hashicorp/terraform-config-inspect" = "latest"
TOML
    ;;
  lock)
    cat > "$repo_root/mise.lock" <<'LOCK'
# regenerated lock
LOCK
    ;;
  *)
    echo "unexpected mise command: $*" >&2
    exit 1
    ;;
esac
EOF

chmod +x "$bin_root/mise"

assert_contains_file() {
  local file="$1"
  local needle="$2"
  local description="$3"

  printf "%-72s ... " "$description"

  if grep -Fq "$needle" "$file"; then
    PASSED=$((PASSED + 1))
    printf "%b\n" "${GREEN}✓${NC}"
  else
    FAILED=$((FAILED + 1))
    printf "%b\n" "${RED}✗${NC}"
  fi
}

assert_not_contains_file() {
  local file="$1"
  local needle="$2"
  local description="$3"

  printf "%-72s ... " "$description"

  if ! grep -Fq "$needle" "$file"; then
    PASSED=$((PASSED + 1))
    printf "%b\n" "${GREEN}✓${NC}"
  else
    FAILED=$((FAILED + 1))
    printf "%b\n" "${RED}✗${NC}"
  fi
}

echo "======================================================================"
echo "Testing tool version upgrade helper"
echo "======================================================================"
echo

MISE_TEST_LOG="$log_file" REPO_ROOT="$fixture_root" PATH="$bin_root:$PATH" bash "$repo_root/$SCRIPT"

assert_contains_file "$log_file" "mise:install" "Runs mise install"
assert_contains_file "$log_file" "mise:upgrade --local --bump" "Runs mise upgrade with local bump"
assert_contains_file "$log_file" "mise:lock" "Regenerates lockfile"
assert_contains_file "$fixture_root/.tool-versions" "terraform 1.13.3" "Syncs terraform version to .tool-versions"
assert_contains_file "$fixture_root/.tool-versions" "python 3.13" "Syncs python version to .tool-versions"
assert_contains_file "$fixture_root/.tool-versions" "go:github.com/hashicorp/terraform-config-inspect latest" "Preserves tool aliases from mise.toml"
assert_not_contains_file "$fixture_root/.tool-versions" "terraform 1.13.2" "Removes stale terraform version from .tool-versions"
assert_contains_file "$fixture_root/mise.lock" "# regenerated lock" "Rewrites mise.lock"

echo
printf '%s\n' "" > "$log_file"
cp "$fixture_root/.tool-versions" "$fixture_root/.tool-versions.before"

MISE_TEST_LOG="$log_file" REPO_ROOT="$fixture_root" PATH="$bin_root:$PATH" bash "$repo_root/$SCRIPT" --dry-run

assert_contains_file "$log_file" "mise:outdated --local --bump" "Dry-run calls mise outdated only"
assert_not_contains_file "$log_file" "mise:upgrade --local --bump" "Dry-run does not run upgrades"

if cmp -s "$fixture_root/.tool-versions.before" "$fixture_root/.tool-versions"; then
  PASSED=$((PASSED + 1))
  printf "%-72s ... %b\n" "Dry-run leaves .tool-versions unchanged" "${GREEN}✓${NC}"
else
  FAILED=$((FAILED + 1))
  printf "%-72s ... %b\n" "Dry-run leaves .tool-versions unchanged" "${RED}✗${NC}"
fi

echo
echo "======================================================================"
echo "Test Summary"
echo "======================================================================"
printf "Passed: %b\n" "${GREEN}${PASSED}${NC}"
printf "Failed: %b\n" "${RED}${FAILED}${NC}"
printf "Total:  %d\n" $((PASSED + FAILED))
echo

if [[ "$FAILED" -eq 0 ]]; then
  printf "%b\n" "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  printf "%b\n" "${RED}✗ Some tests failed!${NC}"
  exit 1
fi
