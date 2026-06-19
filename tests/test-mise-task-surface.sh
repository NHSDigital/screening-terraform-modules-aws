#!/usr/bin/env bash

set -euo pipefail

FAILED=0
PASSED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

MiseFile="mise.toml"

# Tasks intentionally kept active for developer/manual use.
# These are part of the maintained task surface even if not invoked in CI hooks.
ALLOWED_MANUAL_ACTIVE_TASKS=(
  "terraform-derive-module-constraints"
  "terraform-wrapper"
)

assert_success() {
  local ok="$1"
  local label="$2"

  printf "%-70s ... " "$label"
  if [[ "$ok" == "true" ]]; then
    PASSED=$((PASSED + 1))
    printf "%b\n" "${GREEN}✓${NC}"
  else
    FAILED=$((FAILED + 1))
    printf "%b\n" "${RED}✗${NC}"
  fi
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

echo "======================================================================"
echo "Testing mise task surface policy"
echo "======================================================================"
echo

if [[ ! -f "$MiseFile" ]]; then
  echo "Expected $MiseFile to exist" >&2
  exit 1
fi

mapfile -t active_tasks < <(rg '^\[tasks\.([^\]]+)\]$' "$MiseFile" -or '$1' | sort -u)
mapfile -t commented_tasks < <(rg '^# \[tasks\.([^\]]+)\]$' "$MiseFile" -or '$1' | sort -u)

if [[ "${#active_tasks[@]}" -eq 0 ]]; then
  echo "No active tasks were found in $MiseFile" >&2
  exit 1
fi

mapfile -t referenced_tasks < <(
  rg -n 'mise run [A-Za-z0-9._-]+' \
    .github/workflows \
    .github/actions \
    .pre-commit-config.yaml \
    README.md \
    tests \
    | sed -E 's/.*mise run ([A-Za-z0-9._-]+).*/\1/' \
    | sort -u
)

if [[ "${#referenced_tasks[@]}" -eq 0 ]]; then
  echo "No referenced mise tasks were discovered. Check search inputs." >&2
  exit 1
fi

# 1) Every referenced task must be active.
for task in "${referenced_tasks[@]}"; do
  if contains "$task" "${active_tasks[@]}"; then
    assert_success true "Referenced task is active: $task"
  else
    assert_success false "Referenced task is active: $task"
  fi
done

# 2) Every active task must be referenced or explicitly allowed manual.
for task in "${active_tasks[@]}"; do
  if contains "$task" "${referenced_tasks[@]}" || contains "$task" "${ALLOWED_MANUAL_ACTIVE_TASKS[@]}"; then
    assert_success true "Active task is referenced/allowed: $task"
  else
    assert_success false "Active task is referenced/allowed: $task"
  fi
done

# 3) No commented-out task may be referenced by automation/docs/tests.
for task in "${commented_tasks[@]}"; do
  if contains "$task" "${referenced_tasks[@]}"; then
    assert_success false "Commented task is not referenced: $task"
  else
    assert_success true "Commented task is not referenced: $task"
  fi
done

echo
echo "======================================================================"
echo "Test Summary"
echo "======================================================================"
printf "Passed: %b\n" "${GREEN}${PASSED}${NC}"
printf "Failed: %b\n" "${RED}${FAILED}${NC}"
printf "Total:  %d\n" $((PASSED + FAILED))
echo

if [[ "$FAILED" -eq 0 ]]; then
  printf "%b\n" "${GREEN}✓ Task surface policy checks passed!${NC}"
  exit 0
else
  printf "%b\n" "${RED}✗ Task surface policy checks failed!${NC}"
  exit 1
fi
