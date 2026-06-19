#!/usr/bin/env bats
# Test suite for scripts/terraform/upgrade-module.sh
#
# Tests the Terraform module upgrade helper using mock binaries.

load test_helper/assertions

setup_file() {
  export REPO_ROOT
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  export SCRIPT="scripts/terraform/upgrade-module.sh"

  export FIXTURE_ROOT
  FIXTURE_ROOT="$(mktemp -d "$REPO_ROOT/tmp/upgrade-module-test.XXXXXX")"
  export RELATIVE_FIXTURE_ROOT="${FIXTURE_ROOT#"${REPO_ROOT}"/}"

  export BIN_ROOT
  BIN_ROOT="$(mktemp -d)"

  export LOG_FILE="$FIXTURE_ROOT/calls.log"

  # Create mock terraform binary
  cat > "$BIN_ROOT/terraform" <<EOF
#!/usr/bin/env bash
printf '%s\n' "terraform:\$*" >> "$LOG_FILE"
exit 0
EOF

  # Create mock pre-commit binary
  cat > "$BIN_ROOT/pre-commit" <<EOF
#!/usr/bin/env bash
printf '%s\n' "pre-commit:\$*" >> "$LOG_FILE"
exit 0
EOF

  chmod +x "$BIN_ROOT/terraform" "$BIN_ROOT/pre-commit"

  # Create fixture module directories
  mkdir -p "$FIXTURE_ROOT/infrastructure/modules/example-one"
  mkdir -p "$FIXTURE_ROOT/infrastructure/modules/example-two"

  cat > "$FIXTURE_ROOT/infrastructure/modules/example-one/main.tf" <<'EOF'
terraform {
  required_version = ">= 1.13"
}
EOF

  cat > "$FIXTURE_ROOT/infrastructure/modules/example-one/README.md" <<'EOF'
# Example one
EOF

  cat > "$FIXTURE_ROOT/infrastructure/modules/example-two/main.tf" <<'EOF'
terraform {
  required_version = ">= 1.13"
}
EOF

  cat > "$FIXTURE_ROOT/infrastructure/modules/example-two/readme.md" <<'EOF'
# Example two
EOF
}

teardown_file() {
  rm -rf "$FIXTURE_ROOT" "$BIN_ROOT"
}

# --- Single-module upgrade ---

@test "single-module: init uses -upgrade flag" {
  : > "$LOG_FILE"
  PATH="$BIN_ROOT:$PATH" bash "$REPO_ROOT/$SCRIPT" "$FIXTURE_ROOT/infrastructure/modules/example-one"
  assert_file_contains "$LOG_FILE" "terraform:-chdir=$RELATIVE_FIXTURE_ROOT/infrastructure/modules/example-one init -upgrade"
}

@test "single-module: providers lock runs with all target platforms" {
  assert_file_contains "$LOG_FILE" "terraform:-chdir=$RELATIVE_FIXTURE_ROOT/infrastructure/modules/example-one providers lock -platform=linux_arm64 -platform=linux_amd64 -platform=darwin_arm64 -platform=darwin_amd64 -platform=windows_amd64"
}

@test "single-module: terraform_docs runs against README.md" {
  assert_file_contains "$LOG_FILE" "pre-commit:run terraform_docs --files $RELATIVE_FIXTURE_ROOT/infrastructure/modules/example-one/README.md"
}

# --- Update-all upgrade ---

@test "update-all: touches a lowercase-docs module" {
  : > "$LOG_FILE"
  PATH="$BIN_ROOT:$PATH" bash "$REPO_ROOT/$SCRIPT" update-all <<< 'yes' >/dev/null
  assert_file_contains "$LOG_FILE" "terraform:-chdir=infrastructure/modules/api-gateway init -upgrade"
}

@test "update-all: touches an uppercase-docs module" {
  assert_file_contains "$LOG_FILE" "terraform:-chdir=infrastructure/modules/license-manager init -upgrade"
}

@test "update-all: uses README.md symlink for lowercase docs" {
  assert_file_contains "$LOG_FILE" "pre-commit:run terraform_docs --files infrastructure/modules/api-gateway/README.md"
}

@test "update-all: processes modules sequentially" {
  assert_line_order "$LOG_FILE" \
    "terraform:-chdir=infrastructure/modules/api-gateway init -upgrade" \
    "terraform:-chdir=infrastructure/modules/license-manager init -upgrade"
}
