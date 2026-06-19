#!/usr/bin/env bats
# Test suite for verifying GitHub Actions workflow security pinning.
#
# Validates that workflow files use immutable action references (commit SHAs)
# and have version comments for human readability.

load test_helper/assertions

# --- stage-1-pre-commit.yml ---

@test "stage-1-pre-commit.yml: actions/checkout pinned to SHA" {
  assert_file_matches ".github/workflows/stage-1-pre-commit.yml" "uses:.*actions/checkout@[0-9a-f]{40}.*#"
}

@test "stage-1-pre-commit.yml: jdx/mise-action pinned to SHA" {
  assert_file_matches ".github/workflows/stage-1-pre-commit.yml" "uses:.*jdx/mise-action@[0-9a-f]{40}.*#"
}

@test "stage-1-pre-commit.yml: actions/cache pinned to SHA" {
  assert_file_matches ".github/workflows/stage-1-pre-commit.yml" "uses:.*actions/cache@[0-9a-f]{40}.*#"
}

@test "stage-1-pre-commit.yml: AWS region configuration present" {
  assert_file_contains ".github/workflows/stage-1-pre-commit.yml" "AWS_DEFAULT_REGION"
}

@test "stage-1-pre-commit.yml: Terraform plugin cache configured" {
  assert_file_contains ".github/workflows/stage-1-pre-commit.yml" "TF_PLUGIN_CACHE_DIR"
}

# --- dependency-tools-mise-upgrade.yml ---

@test "dependency-tools-mise-upgrade.yml: actions/checkout pinned to SHA" {
  assert_file_matches ".github/workflows/dependency-tools-mise-upgrade.yml" "uses:.*actions/checkout@[0-9a-f]{40}.*#"
}

@test "dependency-tools-mise-upgrade.yml: jdx/mise-action pinned to SHA" {
  assert_file_matches ".github/workflows/dependency-tools-mise-upgrade.yml" "uses:.*jdx/mise-action@[0-9a-f]{40}.*#"
}

@test "dependency-tools-mise-upgrade.yml: peter-evans/create-pull-request pinned to SHA" {
  assert_file_matches ".github/workflows/dependency-tools-mise-upgrade.yml" "uses:.*peter-evans/create-pull-request@[0-9a-f]{40}.*#"
}

@test "dependency-tools-mise-upgrade.yml: uses mise run update-tool-versions" {
  assert_file_contains ".github/workflows/dependency-tools-mise-upgrade.yml" "mise run update-tool-versions"
}

# --- Pre-commit configuration ---

@test "pre-commit config: repos pinned to commit SHAs" {
  assert_file_matches ".pre-commit-config.yaml" "rev:.*[0-9a-f]{40}"
}

@test "pre-commit config: version comments for readability" {
  assert_file_matches ".pre-commit-config.yaml" "#.*v[0-9]"
}

@test "pre-commit config: local conventional commit validator" {
  assert_file_contains ".pre-commit-config.yaml" "scripts/githooks/validate-conventional-commit.sh"
}

@test "pre-commit config: provider generator uses mise task" {
  assert_file_contains ".pre-commit-config.yaml" "mise run githooks-generate-terraform-providers"
}

@test "pre-commit config: shellcheck hook uses wrapper task" {
  assert_file_contains ".pre-commit-config.yaml" "mise run shellscript-linter"
}

@test "shellcheck wrapper supports Docker fallback override" {
  assert_file_contains "scripts/shellscript-linter.sh" "FORCE_USE_DOCKER"
}

# --- Custom hooks implementation ---

@test "conventional commit validator script is executable" {
  [ -x "scripts/githooks/validate-conventional-commit.sh" ]
}

@test "provider generator script is executable" {
  [ -x "scripts/githooks/generate-terraform-providers.sh" ]
}

# --- Tool version file consistency ---

@test ".tool-versions file exists" {
  assert_file_exists ".tool-versions"
}

@test "mise.toml file exists" {
  assert_file_exists "mise.toml"
}

@test "mise.lock file exists" {
  assert_file_exists "mise.lock"
}

@test "terraform version in sync between .tool-versions and mise.toml" {
  local tv_version mt_version
  tv_version=$(grep "^terraform " ".tool-versions" | awk '{print $2}')
  mt_version=$(grep 'terraform.*=' "mise.toml" | grep -v '#' | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  [ "$tv_version" = "$mt_version" ]
}

@test "pre-commit version in .tool-versions" {
  assert_file_matches ".tool-versions" "pre-commit 4\\.6\\.0"
}

@test "pre-commit version in mise.toml" {
  assert_file_matches "mise.toml" "pre-commit.*4\\.6\\.0"
}
