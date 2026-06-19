#!/usr/bin/env bash
# DEPRECATED: This test file has been replaced by test-conventional-commit.bats
# which uses the bats-core test framework. Run: bats tests/test-conventional-commit.bats
#
# Test suite for scripts/githooks/validate-conventional-commit.sh
#
# Tests the bash-based conventional commit message validator.
# Replaces external compilerla/conventional-pre-commit dependency.
#
# Usage:
#   bash tests/test-conventional-commit.sh
#   bash tests/test-conventional-commit.sh verbose

VALIDATOR="scripts/githooks/validate-conventional-commit.sh"
FAILED=0
PASSED=0
VERBOSE="${1:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test a valid commit message
test_valid() {
  local msg="$1"
  local description="$2"

  printf "Testing: %-50s ... " "$description"
  echo "$msg" > /tmp/test-commit-msg.txt

  if bash "$VALIDATOR" /tmp/test-commit-msg.txt >/dev/null 2>&1; then
    PASSED=$((PASSED + 1))
    printf "${GREEN}✓${NC}\n"
    if [ -n "$VERBOSE" ]; then
      printf "  Message: %s\n" "$msg"
    fi
  else
    FAILED=$((FAILED + 1))
    printf "${RED}✗${NC}\n"
    printf "  Message: %s\n" "$msg"
  fi
}

# Test an invalid commit message
test_invalid() {
  local msg="$1"
  local description="$2"

  printf "Testing: %-50s ... " "$description"
  echo "$msg" > /tmp/test-commit-msg.txt

  if ! bash "$VALIDATOR" /tmp/test-commit-msg.txt >/dev/null 2>&1; then
    PASSED=$((PASSED + 1))
    printf "${GREEN}✓${NC}\n"
    if [ -n "$VERBOSE" ]; then
      printf "  Message: %s\n" "$msg"
    fi
  else
    FAILED=$((FAILED + 1))
    printf "${RED}✗${NC}\n"
    printf "  Message: %s\n" "$msg"
  fi
}

echo "======================================================================"
echo "Testing Conventional Commit Validator"
echo "======================================================================"
echo ""

# Valid commits with scope
printf "${YELLOW}Valid commits (with scope):${NC}\n"
test_valid "feat(pre-commit): replace external hook with bash validator" "feat with scope"
test_valid "fix(tools): consolidate mise.toml and .tool-versions" "fix with scope"
test_valid "docs(readme): update installation instructions" "docs with scope"
test_valid "docs(README.md): update example using jdx/mise-action version pinning" "docs with dotted scope"
test_valid "feat!: remove legacy validator" "feat with breaking change marker"
test_valid "feat(validators)!: replace external validator" "feat with scope and breaking marker"
test_valid "style(formatting): apply prettier to all files" "style with scope"
test_valid "refactor(workflows): simplify GitHub Actions configuration" "refactor with scope"
test_valid "perf(ci): optimize terraform plugin caching" "perf with scope"
test_valid "test(validators): add comprehensive test suite" "test with scope"
test_valid "build(deps): update terraform to 1.13.2" "build with scope"
test_valid "ci(pre-commit): update hook configuration" "ci with scope"
test_valid "chore(deps): bump mise to 2024.6.0" "chore with scope"
test_valid "revert(pre-commit): revert breaking change to hook config" "revert with scope"
echo ""

# Valid commits without scope
printf "${YELLOW}Valid commits (without scope):${NC}\n"
test_valid "feat: add support for custom tool versions" "feat without scope"
test_valid "fix: resolve missing shellcheck dependency" "fix without scope"
test_valid "docs: clarify mise.toml requirements" "docs without scope"
echo ""

# Invalid commits - wrong format
printf "${YELLOW}Invalid commits (wrong format):${NC}\n"
test_invalid "invalid message" "No type prefix"
test_invalid "feat add new feature" "Missing colon after type"
test_invalid "feat: " "Empty description"
test_invalid "feat(scope) missing colon" "Missing colon with scope"
test_invalid "docs(read me): invalid spaced scope" "Invalid scope with spaces"
echo ""

# Invalid commits - wrong type
printf "${YELLOW}Invalid commits (invalid type):${NC}\n"
test_invalid "feature(scope): add new feature" "Invalid type: feature"
test_invalid "bug(scope): fix something" "Invalid type: bug"
test_invalid "hotfix(scope): urgent fix" "Invalid type: hotfix"
test_invalid "FEAT(scope): uppercase type" "Invalid type: FEAT"
echo ""

# Summary
echo "======================================================================"
echo "Test Summary"
echo "======================================================================"
printf "Passed: ${GREEN}%d${NC}\n" "$PASSED"
printf "Failed: ${RED}%d${NC}\n" "$FAILED"
printf "Total:  %d\n" $((PASSED + FAILED))
echo ""

if [ $FAILED -eq 0 ]; then
  printf "${GREEN}✓ All tests passed!${NC}\n"
  exit 0
else
  printf "${RED}✗ Some tests failed!${NC}\n"
  exit 1
fi
