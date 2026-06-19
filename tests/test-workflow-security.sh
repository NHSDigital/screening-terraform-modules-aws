#!/usr/bin/env bash
# DEPRECATED: This test file has been replaced by test-workflow-security.bats
# which uses the bats-core test framework. Run: bats tests/test-workflow-security.bats
#
# Test suite for verifying GitHub Actions workflow security pinning
#
# Validates that workflow files use immutable action references (commit SHAs)
# and have version comments for human readability.
#
# Usage:
#   bash tests/test-workflow-security.sh
#   bash tests/test-workflow-security.sh verbose

FAILED=0
PASSED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if a file exists
check_file_exists() {
  local file="$1"
  if [ ! -f "$file" ]; then
    printf "%b File not found: %s\n" "${RED}✗${NC}" "$file"
    exit 1
  fi
}

# Test helper: check if action is pinned
test_action_pinned() {
  local file="$1"
  local action_name="$2"

  printf "%-60s ... " "Action '$action_name' pinned to SHA"

  # Find the uses line and check it has a commit SHA (40 hex) and version comment
  if grep -q "uses:.*@[0-9a-f]\{40\}.*#" "$file"; then
    PASSED=$((PASSED + 1))
    printf "%b\n" "${GREEN}✓${NC}"
  else
    FAILED=$((FAILED + 1))
    printf "%b\n" "${RED}✗${NC}"
  fi
}

# Test helper: check if pattern exists
test_pattern_exists() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  printf "%-60s ... " "$description"

  if grep -q "$pattern" "$file"; then
    PASSED=$((PASSED + 1))
    printf "%b\n" "${GREEN}✓${NC}"
  else
    FAILED=$((FAILED + 1))
    printf "%b\n" "${RED}✗${NC}"
  fi
}

echo "======================================================================"
echo "Verifying GitHub Actions Workflow Security Pinning"
echo "======================================================================"
echo ""

# Check stage-1-pre-commit.yml
printf "%b\n" "${YELLOW}Workflow: .github/workflows/stage-1-pre-commit.yml${NC}"
check_file_exists ".github/workflows/stage-1-pre-commit.yml"

test_action_pinned ".github/workflows/stage-1-pre-commit.yml" "actions/checkout"
test_action_pinned ".github/workflows/stage-1-pre-commit.yml" "jdx/mise-action"
test_action_pinned ".github/workflows/stage-1-pre-commit.yml" "actions/cache"
test_pattern_exists ".github/workflows/stage-1-pre-commit.yml" "AWS_DEFAULT_REGION" "AWS region configuration"
test_pattern_exists ".github/workflows/stage-1-pre-commit.yml" "TF_PLUGIN_CACHE_DIR" "Terraform plugin cache"
echo ""

# Check dependency-tools-mise-upgrade.yml
printf "%b\n" "${YELLOW}Workflow: .github/workflows/dependency-tools-mise-upgrade.yml${NC}"
check_file_exists ".github/workflows/dependency-tools-mise-upgrade.yml"

test_action_pinned ".github/workflows/dependency-tools-mise-upgrade.yml" "actions/checkout"
test_action_pinned ".github/workflows/dependency-tools-mise-upgrade.yml" "jdx/mise-action"
test_action_pinned ".github/workflows/dependency-tools-mise-upgrade.yml" "peter-evans/create-pull-request"
test_pattern_exists ".github/workflows/dependency-tools-mise-upgrade.yml" "mise run update-tool-versions" "Shared tool-version update helper task is used"
echo ""

# Check pre-commit configuration
printf "%b\n" "${YELLOW}Pre-commit Configuration: .pre-commit-config.yaml${NC}"
check_file_exists ".pre-commit-config.yaml"

test_pattern_exists ".pre-commit-config.yaml" "rev:.*[0-9a-f]\\{40\\}" "Repos pinned to commit SHAs"
test_pattern_exists ".pre-commit-config.yaml" "#.*v[0-9]" "Version comments for readability"
test_pattern_exists ".pre-commit-config.yaml" "scripts/githooks/validate-conventional-commit.sh" "Local conventional commit validator"
test_pattern_exists ".pre-commit-config.yaml" "mise run githooks-generate-terraform-providers" "Local provider generator uses mise task"
test_pattern_exists ".pre-commit-config.yaml" "mise run shellscript-linter" "Shellcheck hook uses wrapper task"
test_pattern_exists "scripts/shellscript-linter.sh" "FORCE_USE_DOCKER" "Shellcheck wrapper supports Docker fallback override"
echo ""

# Check custom hooks exist
printf "%b\n" "${YELLOW}Custom Hooks: Implementation${NC}"
check_file_exists "scripts/githooks/validate-conventional-commit.sh"

if [ -x "scripts/githooks/validate-conventional-commit.sh" ]; then
  PASSED=$((PASSED + 1))
  printf "%-60s ... " "Validator script is executable"
  printf "%b\n" "${GREEN}✓${NC}"
else
  FAILED=$((FAILED + 1))
  printf "%-60s ... " "Validator script is executable"
  printf "%b\n" "${RED}✗${NC}"
fi

if [ -x "scripts/githooks/generate-terraform-providers.sh" ]; then
  PASSED=$((PASSED + 1))
  printf "%-60s ... " "Provider generator script is executable"
  printf "%b\n" "${GREEN}✓${NC}"
else
  FAILED=$((FAILED + 1))
  printf "%-60s ... " "Provider generator script is executable"
  printf "%b\n" "${RED}✗${NC}"
fi
echo ""

# Check tool version files
printf "%b\n" "${YELLOW}Tool Version Files: Consistency${NC}"
check_file_exists ".tool-versions"
check_file_exists "mise.toml"
check_file_exists "mise.lock"

# Count matching tool lines
if [ -f ".tool-versions" ] && [ -f "mise.toml" ]; then
  # Get terraform version from both
  TV_VERSION=$(grep "^terraform " ".tool-versions" | awk '{print $2}')
  MT_VERSION=$(grep 'terraform.*=' "mise.toml" | grep -v '#' | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)

  if [ "$TV_VERSION" = "$MT_VERSION" ]; then
    PASSED=$((PASSED + 1))
    printf "%-60s ... " "Terraform versions in sync"
    printf "%b\n" "${GREEN}✓${NC}"
  else
    FAILED=$((FAILED + 1))
    printf "%-60s ... " "Terraform versions in sync"
    printf "%b\n" "${RED}✗${NC}"
    printf "  .tool-versions: %s, mise.toml: %s\n" "$TV_VERSION" "$MT_VERSION"
  fi
fi

test_pattern_exists ".tool-versions" "pre-commit 4\\.6\\.0" "pre-commit version in .tool-versions"
test_pattern_exists "mise.toml" "pre-commit.*4\\.6\\.0" "pre-commit version in mise.toml"
echo ""

# Summary
echo "======================================================================"
echo "Test Summary"
echo "======================================================================"
printf "Passed: %b\n" "${GREEN}${PASSED}${NC}"
printf "Failed: %b\n" "${RED}${FAILED}${NC}"
printf "Total:  %d\n" $((PASSED + FAILED))
echo ""

if [ $FAILED -eq 0 ]; then
  printf "%b\n" "${GREEN}✓ All security checks passed!${NC}"
  exit 0
else
  printf "%b\n" "${RED}✗ Some checks failed!${NC}"
  exit 1
fi
