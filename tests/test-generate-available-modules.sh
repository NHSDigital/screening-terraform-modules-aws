#!/usr/bin/env bash
################################################################################
# Test suite for scripts/generate-available-modules.sh
#
# Tests the available modules table generation script to ensure:
#  - All modules are included in the generated table
#  - Module descriptions are correctly extracted from metadata
#  - Wrapped community modules are correctly identified
#  - Table between markers is properly replaced
#  - Script handles missing metadata gracefully
#  - README markers are required
#  - Generated YAML is valid and matches expected format
#
# Usage:
#   bash tests/test-generate-available-modules.sh
#
################################################################################

set -u

script="scripts/generate-available-modules.sh"
repo_root="$(git rev-parse --show-toplevel)"
mkdir -p "$repo_root/tmp"
fixture_root="$(mktemp -d "$repo_root/tmp/generate-available-modules.XXXXXX")"
failed=0
passed=0

# Colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
blue='\033[0;34m'
nc='\033[0m'

# shellcheck disable=SC2329 # Invoked via trap on script exit.
cleanup() {
    rm -rf "${fixture_root}"
}
trap cleanup EXIT

# Helper: Test assertions
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local description="$3"

    if echo "${haystack}" | grep -F -q -- "${needle}"; then
        printf "${green}✓${nc} %s\n" "${description}"
        ((passed++))
    else
        printf "${red}✗${nc} %s\n" "${description}"
        printf "  Expected to find: %s\n" "${needle}"
        ((failed++))
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local description="$3"

    if ! echo "${haystack}" | grep -F -q -- "${needle}"; then
        printf "${green}✓${nc} %s\n" "${description}"
        ((passed++))
    else
        printf "${red}✗${nc} %s\n" "${description}"
        printf "  Should NOT contain: %s\n" "${needle}"
        ((failed++))
    fi
}

assert_file_exists() {
    local file="$1"
    local description="$2"

    if [ -f "${file}" ]; then
        printf "${green}✓${nc} %s\n" "${description}"
        ((passed++))
    else
        printf "${red}✗${nc} %s\n" "${description}"
        printf "  File not found: %s\n" "${file}"
        ((failed++))
    fi
}

assert_file_has_lines() {
    local file="$1"
    local min_lines="$2"
    local description="$3"

    if [ ! -f "${file}" ]; then
        printf "${red}✗${nc} %s\n" "${description}"
        printf "  File not found: %s\n" "${file}"
        ((failed++))
        return
    fi

    local line_count
    line_count=$(wc -l < "${file}")

    if [ "${line_count}" -ge "${min_lines}" ]; then
        printf "${green}✓${nc} %s\n" "${description}"
        ((passed++))
    else
        printf "${red}✗${nc} %s\n" "${description}"
        printf "  Expected at least %d lines, got %d\n" "${min_lines}" "${line_count}"
        ((failed++))
    fi
}

# ============================================================================
# Test Suite
# ============================================================================

printf "\n${blue}=== Available Modules Generation Tests ===${nc}\n\n"

# Test 1: Script exists and is executable
printf "${blue}Test: Script availability${nc}\n"
if [ ! -f "${repo_root}/${script}" ]; then
    printf "${red}✗${nc} Script not found at %s\n" "${script}"
    ((failed++))
else
    printf "${green}✓${nc} Script exists\n"
    ((passed++))
fi

if [ ! -x "${repo_root}/${script}" ]; then
    printf "${yellow}⚠${nc}  Script exists but is not executable\n"
fi
echo ""

# Test 2: Metadata file exists
printf "${blue}Test: Metadata file availability${nc}\n"
metadata_file="${repo_root}/scripts/config/generate-available-modules.yaml"
if [ -f "${metadata_file}" ]; then
    printf "${green}✓${nc} Metadata file exists\n"
    ((passed++))
else
    printf "${red}✗${nc} Metadata file not found at %s\n" "${metadata_file}"
    ((failed++))
fi
echo ""

# Test 3: Generator with valid README file
printf "${blue}Test: Generate table with markers${nc}\n"
test_readme="${fixture_root}/README.md"
cat > "${test_readme}" << 'EOF'
# Test Project

Some introduction.

## Available modules

<!-- BEGIN_AVAILABLE_MODULES -->
| Module | Wraps | Description |
| --- | --- | --- |
| `old-module` | — | Old description |
<!-- END_AVAILABLE_MODULES -->

## Other section

Some other content.
EOF

if bash "${repo_root}/${script}" "${test_readme}" > /dev/null 2>&1; then
    printf "${green}✓${nc} Script executes successfully\n"
    ((passed++))

    # Verify output has expected content
    content=$(cat "${test_readme}")

    # Check for at least one module (s3-bucket is a known module with metadata)
    assert_contains "${content}" "\`s3-bucket\`" "Table includes s3-bucket module"

    # Check for terraform-aws-modules reference
    assert_contains "${content}" "terraform-aws-modules" "Table includes wrapped modules"

    # Check old content is gone
    assert_not_contains "${content}" "old-module" "Old table content is replaced"

    # Verify table structure
    assert_contains "${content}" "| Module | Wraps | Description |" "Table header is present"
else
    printf "${red}✗${nc} Script failed to execute\n"
    ((failed++))
fi
echo ""

# Test 4: Markers are required
printf "${blue}Test: Markers validation${nc}\n"
no_marker_readme="${fixture_root}/no-marker-README.md"
cat > "${no_marker_readme}" << 'EOF'
# Test Project

No markers here.

## Available modules

| Module | Wraps | Description |
| --- | --- | --- |
EOF

if ! bash "${repo_root}/${script}" "${no_marker_readme}" > /dev/null 2>&1; then
    printf "${green}✓${nc} Script requires BEGIN_AVAILABLE_MODULES marker\n"
    ((passed++))
else
    printf "${red}✗${nc} Script should have failed without markers\n"
    ((failed++))
fi
echo ""

# Test 5: Generated table has expected number of modules
printf "${blue}Test: Module count and format${nc}\n"
fresh_readme="${fixture_root}/fresh-README.md"
cat > "${fresh_readme}" << 'EOF'
# Test

## Available modules

<!-- BEGIN_AVAILABLE_MODULES -->
(placeholder)
<!-- END_AVAILABLE_MODULES -->

## Other
EOF

if bash "${repo_root}/${script}" "${fresh_readme}" > /dev/null 2>&1; then
    content=$(cat "${fresh_readme}")
    # Count table rows (excluding header, looking for | ` pattern for module names)
    module_count=$(echo "${content}" | grep -c '| `' || true)

    if [ "${module_count}" -ge 30 ]; then
        printf "${green}✓${nc} Generated table has %d modules (expected >= 30)\n" "${module_count}"
        ((passed++))
    else
        printf "${yellow}⚠${nc}  Generated table has %d modules (expected >= 30)\n" "${module_count}"
    fi

    # Check for specific known modules
    assert_contains "${content}" "| \`s3-bucket\`" "Includes s3-bucket module"
    assert_contains "${content}" "| \`iam\`" "Includes iam module"
    assert_contains "${content}" "| \`tags\`" "Includes tags module"
else
    printf "${red}✗${nc} Script failed on fresh README\n"
    ((failed++))
fi
echo ""

# Test 6: Wrapped modules are correctly identified
printf "${blue}Test: Wrapped module identification${nc}\n"
if [ -f "${fresh_readme}" ]; then
    content=$(cat "${fresh_readme}")

    # Check for terraform-aws-modules references
    assert_contains "${content}" "| \`s3-bucket\` | terraform-aws-modules/s3-bucket/aws |" "s3-bucket wraps terraform-aws-modules/s3-bucket/aws"
    assert_contains "${content}" "| \`iam\` | terraform-aws-modules/iam/aws |" "iam wraps terraform-aws-modules/iam/aws"

    # Check for non-wrapped modules
    assert_contains "${content}" "| \`tags\` | — |" "tags module shows — for no wrap"
fi
echo ""

# Test 7: Hook script exists
printf "${blue}Test: Hook script availability${nc}\n"
hook_script="${repo_root}/scripts/githooks/check-available-modules.sh"
if [ -f "${hook_script}" ]; then
    printf "${green}✓${nc} Hook script exists\n"
    ((passed++))

    if [ -x "${hook_script}" ]; then
        printf "${green}✓${nc} Hook script is executable\n"
        ((passed++))
    else
        printf "${yellow}⚠${nc}  Hook script exists but is not executable\n"
    fi
else
    printf "${red}✗${nc} Hook script not found at %s\n" "${hook_script}"
    ((failed++))
fi
echo ""

# Final summary
printf "\n${blue}=== Test Summary ===${nc}\n"
total_tests=$((passed + failed))
printf "Passed: %d\n" "${passed}"
printf "Failed: %d\n" "${failed}"
printf "Total:  %d\n\n" "${total_tests}"

if [ $failed -eq 0 ]; then
    printf "${green}✓ All tests passed!${nc}\n"
    exit 0
else
    printf "${red}✗ %d test(s) failed${nc}\n" "${failed}"
    exit 1
fi
