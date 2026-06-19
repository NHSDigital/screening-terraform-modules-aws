#!/usr/bin/env bats
# Test suite for mise task surface policy.
#
# Validates that all `mise run` references in automation/docs point to active
# tasks and no commented-out tasks are referenced.

load test_helper/assertions

setup() {
  MISE_FILE="mise.toml"

  if [[ ! -f "$MISE_FILE" ]]; then
    echo "Expected $MISE_FILE to exist" >&2
    return 1
  fi

  # Tasks intentionally kept active for developer/manual use.
  ALLOWED_MANUAL_ACTIVE_TASKS=(
    "terraform-derive-module-constraints"
    "terraform-wrapper"
  )

  # Discover active tasks (uncommented [tasks.xxx] blocks)
  mapfile -t ACTIVE_TASKS < <(grep -E '^\[tasks\.[^]]+\]$' "$MISE_FILE" | sed -E 's/^\[tasks\.([^]]+)\]$/\1/' | sort -u)

  # Discover commented-out tasks (# [tasks.xxx] blocks)
  mapfile -t COMMENTED_TASKS < <(grep -E '^# \[tasks\.[^]]+\]$' "$MISE_FILE" | sed -E 's/^# \[tasks\.([^]]+)\]$/\1/' | sort -u)

  # Discover all referenced tasks across automation, docs, and tests
  mapfile -t REFERENCED_TASKS < <(
    grep -rEhn 'mise run [A-Za-z0-9._-]+' \
      .github/workflows \
      .github/actions \
      .pre-commit-config.yaml \
      README.md \
      tests \
      | grep -v 'test-mise-task-surface' \
      | sed -E 's/.*mise run ([A-Za-z0-9._-]+).*/\1/' \
      | sort -u
  )
}

contains() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

# --- Every referenced task must be active ---

@test "all referenced tasks are active in mise.toml" {
  local failures=()
  for task in "${REFERENCED_TASKS[@]}"; do
    if ! contains "$task" "${ACTIVE_TASKS[@]}"; then
      failures+=("$task")
    fi
  done
  if [[ ${#failures[@]} -gt 0 ]]; then
    echo "Referenced tasks not active: ${failures[*]}" >&2
    return 1
  fi
}

# --- Every active task must be referenced or explicitly allowed ---

@test "all active tasks are referenced or allowed-manual" {
  local failures=()
  for task in "${ACTIVE_TASKS[@]}"; do
    if ! contains "$task" "${REFERENCED_TASKS[@]}" && ! contains "$task" "${ALLOWED_MANUAL_ACTIVE_TASKS[@]}"; then
      failures+=("$task")
    fi
  done
  if [[ ${#failures[@]} -gt 0 ]]; then
    echo "Active tasks not referenced or allowed: ${failures[*]}" >&2
    return 1
  fi
}

# --- No commented-out task may be referenced ---

@test "no commented-out task is referenced" {
  local failures=()
  for task in "${COMMENTED_TASKS[@]}"; do
    if contains "$task" "${REFERENCED_TASKS[@]}"; then
      failures+=("$task")
    fi
  done
  if [[ ${#failures[@]} -gt 0 ]]; then
    echo "Commented tasks are still referenced: ${failures[*]}" >&2
    return 1
  fi
}

# --- Sanity checks ---

@test "at least one active task found" {
  [[ ${#ACTIVE_TASKS[@]} -gt 0 ]]
}

@test "at least one referenced task found" {
  [[ ${#REFERENCED_TASKS[@]} -gt 0 ]]
}

@test "at least one commented task found" {
  [[ ${#COMMENTED_TASKS[@]} -gt 0 ]]
}
