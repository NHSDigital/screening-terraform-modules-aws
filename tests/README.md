# Testing Guide

## Overview

This repository includes comprehensive test coverage for new features and configurations introduced on the `feature/BCSS-99999-fixup-workflows-actions-precommit` branch:

- **Conventional commit validation** — Native bash implementation replacing external dependency
- **Workflow security** — GitHub Actions and pre-commit hook pinning verification
- **Tool version synchronization** — `.tool-versions` and `mise.toml` consistency
- **Tool version upgrade automation** — Script and workflow logic for upgrading mise-managed tools
- **mise task surface policy** — Referenced tasks remain active and commented-out tasks stay unreferenced

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

#### Tool Version Upgrade Helper Tests

Tests the shared bash helper used both locally and in CI to update `mise.toml`, sync `.tool-versions`, and regenerate `mise.lock`.

```bash
bash tests/test-tool-version-upgrade.sh
```

**Test Coverage:**

- ✓ Calls `mise install`, `mise upgrade --local --bump`, and `mise lock`
- ✓ Synchronizes `.tool-versions` values from upgraded `mise.toml`
- ✓ Preserves alias-style tool keys (for example `go:...`)
- ✓ Supports `--dry-run` without changing files
- ✓ Supports all `--upgrade-level` modes (`patch`, `minor`, `major`, and `all`)

#### Dependabot Configuration Generation Tests

Tests the Dependabot YAML configuration generator that maintains `.github/dependabot.yaml` by automatically discovering all Terraform modules.

```bash
bash tests/test-generate-dependabot-config.sh
```

**Test Coverage:**

- ✓ Script exists and is executable
- ✓ Configuration generation succeeds
- ✓ Generated YAML is valid and parseable
- ✓ All required ecosystem entries preserved (docker, GitHub Actions, npm, pip)
- ✓ All Terraform modules discovered and added (34 modules in infrastructure/modules/)
- ✓ `.terraform/` cache directories excluded from configuration
- ✓ Weekly update schedule configured for all entries
- ✓ Script output is idempotent (running twice produces identical output)
- ✓ All discovered modules accounted for in configuration

#### mise Task Surface Policy Tests

Enforces task-surface consistency between `mise.toml` and current automation/docs references.

```bash
bash tests/test-mise-task-surface.sh
```

**Test Coverage:**

- ✓ Every `mise run <task>` reference in workflows/actions/pre-commit/README/tests points to an active task in `mise.toml`
- ✓ Every active task in `mise.toml` is either referenced or explicitly allowed as maintained manual task
- ✓ No commented-out task in `mise.toml` is referenced by automation/docs/tests

## Test Results

All tests pass with the current configuration:

```text
✓ Conventional Commit Validation: 22 tests passed
✓ Workflow Security Pinning: 15 tests passed
✓ Tool Version Upgrade Helper: 5+ tests passed
✓ Dependabot Configuration Generation: 9+ tests passed
✓ Total: 70+ test cases across 5 test suites
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
mise run githooks-validate-conventional-commit -- /tmp/test-msg.txt
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
