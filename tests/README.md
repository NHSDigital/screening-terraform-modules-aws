# Testing Guide

## Overview

This repository uses [bats-core](https://github.com/bats-core/bats-core) (Bash Automated Testing System) for all shell script tests. Tests are located in `tests/*.bats` with shared assertion helpers in `tests/test_helper/`.

Test coverage includes:

- **Conventional commit validation** — Native bash implementation replacing external dependency
- **Workflow security** — GitHub Actions and pre-commit hook pinning verification
- **Tool version synchronization** — `.tool-versions` and `mise.toml` consistency
- **Tool version upgrade automation** — Script and workflow logic for upgrading mise-managed tools
- **Dependabot config generation** — Automatic Terraform module discovery
- **mise task surface policy** — Referenced tasks remain active and commented-out tasks stay unreferenced

## Prerequisites

- `bats` 1.13.0+ (managed via mise; run `mise install` to set up)

## Running Tests

### Run All Tests

```bash
bash tests/run-all-tests.sh          # Pretty output (default for terminals)
bash tests/run-all-tests.sh --tap    # TAP output (for CI)
bats tests/*.bats                    # Direct bats invocation
```

### Run Individual Test Suites

```bash
bats tests/test-conventional-commit.bats
bats tests/test-workflow-security.bats
bats tests/test-module-upgrade.bats
bats tests/test-tool-version-upgrade.bats
bats tests/test-generate-dependabot-config.bats
bats tests/test-mise-task-surface.bats
```

### Run a Single Test by Name

```bash
bats tests/test-conventional-commit.bats --filter "feat with scope"
```

## Test Suites

### Conventional Commit Validation

Tests the native bash validation script that replaces the external `compilerla/conventional-pre-commit` dependency.

**Coverage:**

- Valid commits with scope: `feat(scope): description`
- Valid commits without scope: `feat: description`
- Invalid format detection (missing colons, empty descriptions)
- Invalid type detection (allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`)

### Workflow Security Pinning

Validates that GitHub Actions and pre-commit hooks use immutable references (commit SHAs) with version comments.

```bash
bash tests/test-workflow-security.sh
bash tests/test-workflow-security.sh verbose  # Show detailed output
```

**Coverage:**

- GitHub Actions pinned to commit SHAs with version comments
- Environment variables configured (AWS_DEFAULT_REGION, TF_PLUGIN_CACHE_DIR)
- Pre-commit repos pinned to commit SHAs
- Local custom hooks exist and are executable
- Tool version files synchronised between `.tool-versions` and `mise.toml`

### Terraform Module Upgrade Helper

Tests the upgrade helper that refreshes provider locks and documentation.

**Coverage:**

- Single-module init with `-upgrade` flag
- Provider lock across all target platforms
- `terraform_docs` invocation against README
- `update-all` mode processes modules sequentially

### Tool Version Upgrade Helper

Tests the shared bash helper used both locally and in CI to update `mise.toml`, sync `.tool-versions`, and regenerate `mise.lock`.

**Coverage:**

- Calls `mise install`, `mise upgrade --local --bump`, and `mise lock`
- Synchronises `.tool-versions` values from upgraded `mise.toml`
- Preserves alias-style tool keys (for example `go:...`)
- Supports `--dry-run` without changing files
- Supports all `--upgrade-level` modes (`patch`, `minor`, `major`, and `all`)

### Dependabot Configuration Generation

Tests the Dependabot YAML configuration generator that maintains `.github/dependabot.yaml`.

**Coverage:**

- Script exists and is executable
- Generated YAML is valid and parseable
- All required ecosystem entries preserved (Docker, GitHub Actions)
- All Terraform modules discovered and included
- `.terraform/` cache directories excluded
- Script output is idempotent
- Template customisations outside markers are preserved

### mise Task Surface Policy

Enforces task-surface consistency between `mise.toml` and current automation/docs references.

**Coverage:**

- Every `mise run <task>` reference points to an active task
- Every active task is either referenced or explicitly allowed as a maintained manual task
- No commented-out task is referenced by automation/docs/tests

## Integration with CI/CD

Tests produce TAP-compliant output for CI integration:

```yaml
# Example GitHub Actions step
- name: Run test suite
  run: bash tests/run-all-tests.sh --tap
```

## Adding New Tests

1. Create a new `.bats` file in `tests/` (e.g., `tests/test-feature-name.bats`)
2. Load shared helpers: `load test_helper/assertions`
3. Tests are automatically picked up by `run-all-tests.sh`

### Test File Template

```bash
#!/usr/bin/env bats
# Test suite for feature-name

load test_helper/assertions

setup_file() {
  # Expensive one-time setup (fixtures, mock binaries)
  export REPO_ROOT
  REPO_ROOT="$(git rev-parse --show-toplevel)"
}

teardown_file() {
  # Clean up fixtures
  :
}

@test "description of expected behaviour" {
  run some_command
  [ "$status" -eq 0 ]
  assert_contains "$output" "expected"
}

@test "file contains expected content" {
  assert_file_contains "path/to/file" "expected string"
}
```

### Available Assertions

Defined in `tests/test_helper/assertions.bash`:

| Function | Purpose |
| --- | --- |
| `assert_file_contains <file> <needle>` | File contains fixed string |
| `assert_file_not_contains <file> <needle>` | File does not contain string |
| `assert_file_exists <path>` | File exists |
| `assert_file_matches <file> <regex>` | File matches regex pattern |
| `assert_line_order <file> <first> <second>` | First string appears before second |
| `assert_contains <haystack> <needle>` | String contains substring |
| `assert_not_contains <haystack> <needle>` | String does not contain substring |

## Debugging Test Failures

```bash
# Run with verbose output
bats tests/test-conventional-commit.bats --trace

# Run a specific failing test
bats tests/test-workflow-security.bats --filter "terraform version"
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
- [Pre-commit configuration](../.pre-commit-config.yaml)
