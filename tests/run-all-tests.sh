#!/usr/bin/env bash
# Run all tests for screening-terraform-modules-aws
#
# Tests include:
#   - Conventional commit validator functionality
#   - GitHub Actions workflow security (action pinning, env vars)
#   - Terraform module upgrade helper behaviour
#   - Pre-commit configuration consistency
#   - Tool version file synchronization
#   - Tool version upgrade automation helper
#
# Usage:
#   bash tests/run-all-tests.sh
#   bash tests/run-all-tests.sh verbose

set -u

VERBOSE="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TOTAL_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

cd "$REPO_ROOT" || exit

echo ""
echo "======================================================================"
echo "Running Comprehensive Test Suite"
echo "======================================================================"
echo ""

# Test 1: Conventional Commit Validator
echo -e "${BLUE}Running: Conventional Commit Validator Tests${NC}"
echo "----------------------------------------------------------------------"
if bash tests/test-conventional-commit.sh "${VERBOSE:-}" > /tmp/test-conventional.log 2>&1; then
  cat /tmp/test-conventional.log
  echo -e "${GREEN}✓ Conventional commit tests passed${NC}"
else
  cat /tmp/test-conventional.log
  echo -e "${RED}✗ Conventional commit tests failed${NC}"
  TOTAL_FAILED=$((TOTAL_FAILED + 1))
fi
echo ""

# Test 2: Workflow Security
echo -e "${BLUE}Running: Workflow Security Pinning Tests${NC}"
echo "----------------------------------------------------------------------"
if bash tests/test-workflow-security.sh "${VERBOSE:-}" > /tmp/test-workflow.log 2>&1; then
  cat /tmp/test-workflow.log
  echo -e "${GREEN}✓ Workflow security tests passed${NC}"
else
  cat /tmp/test-workflow.log
  echo -e "${RED}✗ Workflow security tests failed${NC}"
  TOTAL_FAILED=$((TOTAL_FAILED + 1))
fi
echo ""

# Test 3: Terraform Module Upgrade Helper
echo -e "${BLUE}Running: Terraform Module Upgrade Helper Tests${NC}"
echo "----------------------------------------------------------------------"
if bash tests/test-module-upgrade.sh "${VERBOSE:-}" > /tmp/test-module-upgrade.log 2>&1; then
  cat /tmp/test-module-upgrade.log
  echo -e "${GREEN}✓ Terraform module upgrade helper tests passed${NC}"
else
  cat /tmp/test-module-upgrade.log
  echo -e "${RED}✗ Terraform module upgrade helper tests failed${NC}"
  TOTAL_FAILED=$((TOTAL_FAILED + 1))
fi
echo ""

# Test 4: Tool Version Upgrade Helper
echo -e "${BLUE}Running: Tool Version Upgrade Helper Tests${NC}"
echo "----------------------------------------------------------------------"
if bash tests/test-tool-version-upgrade.sh "${VERBOSE:-}" > /tmp/test-tool-version-upgrade.log 2>&1; then
  cat /tmp/test-tool-version-upgrade.log
  echo -e "${GREEN}✓ Tool version upgrade helper tests passed${NC}"
else
  cat /tmp/test-tool-version-upgrade.log
  echo -e "${RED}✗ Tool version upgrade helper tests failed${NC}"
  TOTAL_FAILED=$((TOTAL_FAILED + 1))
fi
echo ""

# Test 5: Dependabot Configuration Generation
echo -e "${BLUE}Running: Dependabot Configuration Generation Tests${NC}"
echo "----------------------------------------------------------------------"
if bash tests/test-generate-dependabot-config.sh "${VERBOSE:-}" > /tmp/test-dependabot-config.log 2>&1; then
  cat /tmp/test-dependabot-config.log
  echo -e "${GREEN}✓ Dependabot config generation tests passed${NC}"
else
  cat /tmp/test-dependabot-config.log
  echo -e "${RED}✗ Dependabot config generation tests failed${NC}"
  TOTAL_FAILED=$((TOTAL_FAILED + 1))
fi
echo ""

# Final summary
echo "======================================================================"
echo "Test Suite Summary"
echo "======================================================================"

if [ $TOTAL_FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All test suites passed!${NC}"
  echo ""
  echo "Ready for commit and PR:"
  echo "  - Conventional commits validated with native bash hook"
  echo "  - GitHub Actions pinned to immutable commit SHAs"
  echo "  - Terraform module upgrade helper verified"
  echo "  - Pre-commit configuration verified for consistency"
  echo "  - Tool versions synchronized across .tool-versions and mise.toml"
  echo "  - Tool version upgrade helper verified"
  exit 0
else
  echo -e "${RED}✗ $TOTAL_FAILED test suite(s) failed${NC}"
  exit 1
fi
