# Testing Guide

## Overview

This repository includes comprehensive test coverage for new features and configurations introduced on the `feature/BCSS-99999-fixup-workflows-actions-precommit` branch:

- **Conventional commit validation** — Native bash implementation replacing external dependency
- **Workflow security** — GitHub Actions and pre-commit hook pinning verification
- **Tool version synchronization** — `.tool-versions` and `mise.toml` consistency

## Running Tests

### Run All Tests

```bash
bash tests/run-all-tests.sh
bash tests/run-all-tests.sh verbose  # Show message examples
```

### Run Individual Test Suites

#### Conventional Commit Validation Tests

Tests the native bash validation script that replaces the external `compilerla/conventional-pre-commit` dependency.

```bash
bash tests/test-conventional-commit.sh
bash tests/test-conventional-commit.sh verbose  # Show detailed output
```

**Test Coverage:**

- ✓ Valid commits with scope: `feat(scope): description`
- ✓ Valid commits without scope: `feat: description`
- ✓ Invalid format detection (missing colons, empty descriptions)
- ✓ Invalid type detection (allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`)
- 22 total test cases

#### Workflow Security Pinning Tests

Validates that GitHub Actions and pre-commit hooks use immutable references (commit SHAs) with version comments.

```bash
bash tests/test-workflow-security.sh
bash tests/test-workflow-security.sh verbose  # Show detailed output
```

**Test Coverage:**

- ✓ GitHub Actions pinned to commit SHAs (actions/checkout, jdx/mise-action, actions/cache)
- ✓ Environment variables configured (AWS_DEFAULT_REGION, TF_PLUGIN_CACHE_DIR)
- ✓ shellcheck Docker fallback capability retained (FORCE_USE_DOCKER support in wrapper)
- ✓ Pre-commit repos pinned to commit SHAs
- ✓ Version comments present for human readability
- ✓ Local custom hooks exist and are executable
- ✓ Tool version files synchronized
- 15 total test cases

## Test Results

All tests pass with the current configuration:

```text
✓ Conventional Commit Validation: 22 tests passed
✓ Workflow Security Pinning: 15 tests passed
✓ Total: 37 tests passed
```

## Integration with CI/CD

Tests are designed to run locally and in CI/CD pipelines:

```yaml
# Example GitHub Actions step
- name: Run test suite
  run: bash tests/run-all-tests.sh
```

## Adding New Tests

To add new tests:

1. Create a new test file in `tests/` directory (e.g., `tests/test-feature-name.sh`)
2. Make it executable: `chmod +x tests/test-feature-name.sh`
3. Add a call to the test runner in `tests/run-all-tests.sh`

### Test Script Template

```bash
#!/usr/bin/env bash
# Test suite for feature-name
# Usage: bash tests/test-feature-name.sh

FAILED=0
PASSED=0

# Test helper
test_case() {
  local description="$1"
  local command="$2"
  printf "Testing: %-50s ... " "$description"

  if eval "$command" >/dev/null 2>&1; then
    PASSED=$((PASSED + 1))
    echo "✓"
  else
    FAILED=$((FAILED + 1))
    echo "✗"
  fi
}

# Run tests
test_case "Description" "command"

# Summary
if [ $FAILED -eq 0 ]; then
  exit 0
else
  exit 1
fi
```

## Debugging Test Failures

### Verbose Output

Run tests with verbose flag to see detailed information:

```bash
bash tests/test-conventional-commit.sh verbose
bash tests/test-workflow-security.sh verbose
bash tests/run-all-tests.sh verbose
```

### Manual Testing

Test individual components manually:

```bash
# Test conventional commit validator directly
echo "feat(scope): test message" > /tmp/test-msg.txt
bash scripts/githooks/validate-conventional-commit.sh /tmp/test-msg.txt
echo "Exit code: $?"  # 0 = pass, 1 = fail

# Check action pinning
grep "uses:" .github/workflows/stage-1-pre-commit.yml | grep "@"

# Verify pre-commit config
grep "rev:" .pre-commit-config.yaml
```

## Related Documentation

- [Run Git hooks on commit](../docs/user-guides/Run_Git_hooks_on_commit.md)
- [Test GitHub Actions locally](../docs/user-guides/Test_GitHub_Actions_locally.md)
- [Pre-commit configuration](.pre-commit-config.yaml)
