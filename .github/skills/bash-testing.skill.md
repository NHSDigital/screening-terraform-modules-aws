---
name: "bash-testing"
description: "Bash test framework and patterns for screening-terraform-modules-aws. Native shell testing without external dependencies. Covers test structure, mocking, assertions, and integration with the CI/CD pipeline."
---

# Bash Testing Skill

## Overview

This repository uses a lightweight Bash test framework for:

- Validating shell scripts (`upgrade-module.sh`, git hooks)
- Testing conventional commit enforcement
- Verifying GitHub Actions workflow security (pinned versions)
- Ensuring module upgrade helper behaves correctly

All tests run via `bash tests/run-all-tests.sh` in the CI/CD pipeline and locally.

## Test File Structure

Tests live in `tests/`:

```text
tests/
├── run-all-tests.sh                # Orchestrator; runs all test suites
├── test-conventional-commit.sh    # Validates conventional commit message format
├── test-workflow-security.sh      # Ensures GitHub Actions use pinned versions
└── test-module-upgrade.sh         # Tests the Terraform upgrade helper script
```

## Writing a Bash Test

### Anatomy of a Test

```bash
#!/usr/bin/env bash

set -euo pipefail

# Setup: Create fixtures, mock functions, initialize state
setup() {
  # Prepare test environment
  test_dir=$(mktemp -d)
  echo "Test directory: $test_dir"
}

# Teardown: Clean up temporary files
cleanup() {
  [ -d "$test_dir" ] && rm -rf "$test_dir"
}

trap cleanup EXIT

# Test case 1
test_example_behaviour() {
  # Arrange
  local input="test value"

  # Act
  local result=$(some_function "$input")

  # Assert
  if [[ "$result" == "expected value" ]]; then
    echo "✓ Test passed"
  else
    echo "✗ Test failed: expected 'expected value', got '$result'"
    return 1
  fi
}

# Run all tests
setup
test_example_behaviour
echo "All tests passed"
```

### Assertion Patterns

```bash
# String equality
assert_equals() {
  local expected="$1" actual="$2"
  if [[ "$actual" != "$expected" ]]; then
    echo "✗ FAIL: expected '$expected', got '$actual'" >&2
    return 1
  fi
  echo "✓ PASS"
}

# File exists
assert_file_exists() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "✗ FAIL: file not found: $file" >&2
    return 1
  fi
  echo "✓ PASS"
}

# Command succeeds
assert_command_succeeds() {
  local cmd="$1"
  if ! eval "$cmd"; then
    echo "✗ FAIL: command failed: $cmd" >&2
    return 1
  fi
  echo "✓ PASS"
}

# Exit code
assert_exit_code() {
  local expected="$1" actual="$2"
  if [[ "$actual" -ne "$expected" ]]; then
    echo "✗ FAIL: expected exit code $expected, got $actual" >&2
    return 1
  fi
  echo "✓ PASS"
}
```

## Mocking Functions

For testing scripts that call external commands (e.g., `terraform`, `pre-commit`), create mock stubs:

```bash
# Mock terraform to capture arguments
terraform() {
  echo "$@" >> "$test_dir/terraform_calls.txt"
  return 0
}

# Export so subshells can use it
export -f terraform

# Later, verify the calls
if grep -q "init -upgrade" "$test_dir/terraform_calls.txt"; then
  echo "✓ terraform init -upgrade was called"
fi
```

### Mocking with Argument Capture

```bash
# Capture all calls to a command
mock_command() {
  local cmd="$1"

  # Store original if it exists
  if command -v "$cmd" >/dev/null 2>&1; then
    eval "original_${cmd}=$(command -v $cmd)"
  fi

  # Create mock function
  eval "${cmd}() {
    echo \"\$@\" >> \"$test_dir/${cmd}_calls.txt\"
    return 0
  }"

  export -f "$cmd"
}

# Use it
mock_command terraform
my_script_that_calls_terraform

# Verify
if grep -q "providers lock" "$test_dir/terraform_calls.txt"; then
  echo "✓ providers lock was called"
fi
```

## Test Fixtures

For complex tests (e.g., testing the upgrade helper), create realistic directory structures:

```bash
setup_module_fixtures() {
  local modules_dir="$test_dir/modules"

  # Create a minimal module structure
  mkdir -p "$modules_dir/vpc"
  cat > "$modules_dir/vpc/versions.tf" <<'EOF'
terraform {
  required_version = ">= 1.13"
  required_providers {
    aws = { version = ">= 6.0" }
  }
}
EOF

  cat > "$modules_dir/vpc/README.md" <<'EOF'
# VPC Module
EOF

  echo "Fixtures created in $modules_dir"
}
```

## Running Tests Locally

### Single Test File

```bash
bash tests/test-module-upgrade.sh
```

Output shows pass/fail for each test:

```text
Running test_normalise_module_path_absolute...
✓ Test passed
Running test_normalise_module_path_relative...
✓ Test passed
...
All 7 tests passed
```

### All Tests

```bash
bash tests/run-all-tests.sh
```

Output aggregates all test suites:

```text
Test 1: Conventional Commits
============================
Running conventional commit tests...
22 tests passed

Test 2: Workflow Security
=========================
Running workflow security tests...
16 tests passed

Test 3: Module Upgrade Helper
=============================
Running module upgrade tests...
7 tests passed

=== ALL TESTS PASSED (45 total) ===
```

## Error Handling in Tests

### Fail-Fast

```bash
set -euo pipefail
# -e: exit on any error
# -u: error on undefined variable
# -o pipefail: propagate error in pipe
```

### Graceful Cleanup

Use traps to ensure cleanup happens even on error:

```bash
cleanup() {
  local exit_code=$?

  # Always clean up
  [ -d "$test_dir" ] && rm -rf "$test_dir"

  # Restore original functions/variables
  unset -f mocked_command

  return $exit_code
}

trap cleanup EXIT
```

## CI/CD Integration

Tests run automatically in GitHub Actions:

```yaml
- name: Run All Tests
  run: bash tests/run-all-tests.sh
```

If any test fails, the workflow fails. Test output appears in the CI/CD logs.

## Best Practices

1. **One concern per test** – test a single behavior
2. **Use descriptive names** – `test_normalize_absolute_path_with_dots` not `test_1`
3. **Clean up after yourself** – use `trap cleanup EXIT`
4. **Mock external commands** – don't call real `terraform` in tests
5. **Avoid time-dependent tests** – don't sleep or use dates
6. **Test both success and failure** – assert_exit_code 0 and non-zero cases
7. **Document complex mocks** – explain what the mock does
8. **Keep tests fast** – under 100ms per test is ideal

## Adding a New Test Suite

1. Create `tests/test-<feature>.sh`
2. Follow the structure in existing test files
3. Include setup/cleanup with trap
4. Write focused test functions
5. Exit with status 0 if all pass, non-zero if any fail
6. Add the test to `tests/run-all-tests.sh`

Example:

```bash
#!/usr/bin/env bash
set -euo pipefail

test_dir=$(mktemp -d)

cleanup() {
  [ -d "$test_dir" ] && rm -rf "$test_dir"
}

trap cleanup EXIT

test_feature_works() {
  # Test implementation
  return 0
}

echo "Running feature tests..."
test_feature_works
echo "✓ All feature tests passed"
```

## Debugging Tests

Run with shell tracing:

```bash
bash -x tests/test-module-upgrade.sh
```

Output shows every command executed:

```text
+ terraform() { echo "$@" >> ...
+ test_terraform_init_upgrade
+ local module_path=infrastructure/modules/vpc
+ normalise_module_path infrastructure/modules/vpc
+ echo infrastructure/modules/vpc
...
```

Check temporary files created during tests:

```bash
# Don't delete after test; inspect the files
test_dir="/tmp/test-artifacts"
mkdir -p "$test_dir"
bash tests/test-module-upgrade.sh
ls -la "$test_dir"
```
