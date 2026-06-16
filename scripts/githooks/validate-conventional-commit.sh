#!/usr/bin/env bash
# Validate that commit messages follow the Conventional Commits specification.
#
# Format: type(scope): description
#   type:        feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
#   scope:       optional
#   description: concise summary of the change
#
# Usage:
#   $0 <commit-message-file>
#
# This hook reads the commit message from the specified file and validates it.

set -euo pipefail

ALLOWED_TYPES=(feat fix docs style refactor perf test build ci chore revert)
COMMIT_MSG_FILE="${1:-.git/COMMIT_EDITMSG}"

if [[ ! -f "$COMMIT_MSG_FILE" ]]; then
  echo "ERROR: Commit message file not found: $COMMIT_MSG_FILE" >&2
  exit 1
fi

# Read commit message, strip comments and trailing whitespace
COMMIT_MSG=$(sed '/^#/d' "$COMMIT_MSG_FILE" | sed -e 's/[[:space:]]*$//' | head -1)

if [[ -z "$COMMIT_MSG" ]]; then
  echo "ERROR: Empty commit message." >&2
  exit 1
fi

# Validate format: type(scope): description OR type: description
# Allow optional scope in parentheses
if ! [[ "$COMMIT_MSG" =~ ^([a-z]+)(\([a-z0-9_-]+\))?:\ .+ ]]; then
  echo "ERROR: Commit message does not follow Conventional Commits format." >&2
  echo "Expected format: type(scope): description" >&2
  echo "Got: $COMMIT_MSG" >&2
  exit 1
fi

# Extract type from commit message
COMMIT_TYPE=$(echo "$COMMIT_MSG" | sed 's/^\([a-z]*\).*/\1/')

# Validate that type is in the allowed list
if ! printf '%s\n' "${ALLOWED_TYPES[@]}" | grep -q "^$COMMIT_TYPE$"; then
  echo "ERROR: Invalid commit type: '$COMMIT_TYPE'" >&2
  echo "Allowed types: ${ALLOWED_TYPES[*]}" >&2
  exit 1
fi

exit 0
