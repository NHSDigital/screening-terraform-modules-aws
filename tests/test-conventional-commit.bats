#!/usr/bin/env bats
# Test suite for scripts/githooks/validate-conventional-commit.sh
#
# Tests the bash-based conventional commit message validator.

setup() {
  VALIDATOR="scripts/githooks/validate-conventional-commit.sh"
  COMMIT_MSG_FILE="$(mktemp)"
}

teardown() {
  rm -f "$COMMIT_MSG_FILE"
}

# --- Valid commits with scope ---

@test "valid: feat with scope" {
  echo "feat(pre-commit): replace external hook with bash validator" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -eq 0 ]
}

@test "valid: fix with scope" {
  echo "fix(tools): consolidate mise.toml and .tool-versions" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -eq 0 ]
}

@test "valid: docs with scope" {
  echo "docs(readme): update installation instructions" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -eq 0 ]
}

@test "valid: docs with dotted scope" {
  echo "docs(README.md): update example using jdx/mise-action version pinning" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -eq 0 ]
}

@test "valid: feat with breaking change marker" {
  echo "feat!: remove legacy validator" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -eq 0 ]
}

@test "valid: feat with scope and breaking marker" {
  echo "feat(validators)!: replace external validator" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -eq 0 ]
}

@test "valid: style with scope" {
  echo "style(formatting): apply prettier to all files" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -eq 0 ]
}

@test "valid: refactor with scope" {
  echo "refactor(workflows): simplify GitHub Actions configuration" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -eq 0 ]
}

@test "valid: perf with scope" {
  echo "perf(ci): optimize terraform plugin caching" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -eq 0 ]
}

@test "valid: test with scope" {
  echo "test(validators): add comprehensive test suite" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -eq 0 ]
}

@test "valid: build with scope" {
  echo "build(deps): update terraform to 1.13.2" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -eq 0 ]
}

@test "valid: ci with scope" {
  echo "ci(pre-commit): update hook configuration" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -eq 0 ]
}

@test "valid: chore with scope" {
  echo "chore(deps): bump mise to 2024.6.0" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -eq 0 ]
}

@test "valid: revert with scope" {
  echo "revert(pre-commit): revert breaking change to hook config" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -eq 0 ]
}

# --- Valid commits without scope ---

@test "valid: feat without scope" {
  echo "feat: add support for custom tool versions" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -eq 0 ]
}

@test "valid: fix without scope" {
  echo "fix: resolve missing shellcheck dependency" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -eq 0 ]
}

@test "valid: docs without scope" {
  echo "docs: clarify mise.toml requirements" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -eq 0 ]
}

# --- Invalid commits: wrong format ---

@test "invalid: no type prefix" {
  echo "invalid message" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -ne 0 ]
}

@test "invalid: missing colon after type" {
  echo "feat add new feature" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -ne 0 ]
}

@test "invalid: empty description" {
  echo "feat: " > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -ne 0 ]
}

@test "invalid: missing colon with scope" {
  echo "feat(scope) missing colon" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -ne 0 ]
}

@test "invalid: scope with spaces" {
  echo "docs(read me): invalid spaced scope" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -ne 0 ]
}

# --- Invalid commits: wrong type ---

@test "invalid type: feature" {
  echo "feature(scope): add new feature" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -ne 0 ]
}

@test "invalid type: bug" {
  echo "bug(scope): fix something" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -ne 0 ]
}

@test "invalid type: hotfix" {
  echo "hotfix(scope): urgent fix" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -ne 0 ]
}

@test "invalid type: FEAT (uppercase)" {
  echo "FEAT(scope): uppercase type" > "$COMMIT_MSG_FILE"
  run bash "$VALIDATOR" "$COMMIT_MSG_FILE"
  [ "$status" -ne 0 ]
}
