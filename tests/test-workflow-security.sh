#!/usr/bin/env bash
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
    printf "${RED}✗${NC} File not found: %s\n" "$file"
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
    printf "${GREEN}✓${NC}\n"
  else
    FAILED=$((FAILED + 1))
    printf "${RED}✗${NC}\n"
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
    printf "${GREEN}✓${NC}\n"
  else
    FAILED=$((FAILED + 1))
    printf "${RED}✗${NC}\n"
  fi
}

echo "======================================================================"
echo "Verifying GitHub Actions Workflow Security Pinning"
echo "======================================================================"
echo ""

# Check stage-1-pre-commit.yml
printf "${YELLOW}Workflow: .github/workflows/stage-1-pre-commit.yml${NC}\n"
check_file_exists ".github/workflows/stage-1-pre-commit.yml"

test_action_pinned ".github/workflows/stage-1-pre-commit.yml" "actions/checkout"
test_action_pinned ".github/workflows/stage-1-pre-commit.yml" "jdx/mise-action"
test_action_pinned ".github/workflows/stage-1-pre-commit.yml" "actions/cache"
test_pattern_exists ".github/workflows/stage-1-pre-commit.yml" "AWS_DEFAULT_REGION" "AWS region configuration"
test_pattern_exists ".github/workflows/stage-1-pre-commit.yml" "TF_PLUGIN_CACHE_DIR" "Terraform plugin cache"
test_pattern_exists ".github/workflows/stage-1-pre-commit.yml" "FORCE_USE_DOCKER" "Docker fallback for shellcheck"
echo ""

# Check pre-commit configuration
printf "${YELLOW}Pre-commit Configuration: .pre-commit-config.yaml${NC}\n"
check_file_exists ".pre-commit-config.yaml"

test_pattern_exists ".pre-commit-config.yaml" "rev:.*[0-9a-f]\\{40\\}" "Repos pinned to commit SHAs"
test_pattern_exists ".pre-commit-config.yaml" "#.*v[0-9]" "Version comments for readability"
test_pattern_exists ".pre-commit-config.yaml" "scripts/githooks/validate-conventional-commit.sh" "Local conventional commit validator"
test_pattern_exists ".pre-commit-config.yaml" "scripts/githooks/generate-terraform-providers.sh" "Local provider generator"
echo ""

# Check custom hooks exist
printf "${YELLOW}Custom Hooks: Implementation${NC}\n"
check_file_exists "scripts/githooks/validate-conventional-commit.sh"

if [ -x "scripts/githooks/validate-conventional-commit.sh" ]; then
  PASSED=$((PASSED + 1))
  printf "%-60s ... ${GREEN}✓${NC}\n" "Validator script is executable"
else
  FAILED=$((FAILED + 1))
  printf "%-60s ... ${RED}✗${NC}\n" "Validator script is executable"
fi

if [ -x "scripts/githooks/generate-terraform-providers.sh" ]; then
  PASSED=$((PASSED + 1))
  printf "%-60s ... ${GREEN}✓${NC}\n" "Provider generator script is executable"
else
  FAILED=$((FAILED + 1))
  printf "%-60s ... ${RED}✗${NC}\n" "Provider generator script is executable"
fi
echo ""

# Check tool version files
printf "${YELLOW}Tool Version Files: Consistency${NC}\n"
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
    printf "%-60s ... ${GREEN}✓${NC}\n" "Terraform versions in sync"
  else
    FAILED=$((FAILED + 1))
    printf "%-60s ... ${RED}✗${NC}\n" "Terraform versions in sync"
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
printf "Passed: ${GREEN}%d${NC}\n" "$PASSED"
printf "Failed: ${RED}%d${NC}\n" "$FAILED"
printf "Total:  %d\n" $((PASSED + FAILED))
echo ""

if [ $FAILED -eq 0 ]; then
  printf "${GREEN}✓ All security checks passed!${NC}\n"
  exit 0
else
  printf "${RED}✗ Some checks failed!${NC}\n"
  exit 1
fi
