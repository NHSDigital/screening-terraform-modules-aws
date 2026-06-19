#!/usr/bin/env bash
# Shared assertion helpers for bats tests.
# Load in .bats files with: load test_helper/assertions

# Assert a file contains a fixed string.
# Usage: assert_file_contains <file> <needle>
assert_file_contains() {
  local file="$1"
  local needle="$2"
  if ! grep -Fq -- "$needle" "$file"; then
    echo "Expected file to contain: $needle" >&2
    echo "  File: $file" >&2
    return 1
  fi
}

# Assert a file does NOT contain a fixed string.
# Usage: assert_file_not_contains <file> <needle>
assert_file_not_contains() {
  local file="$1"
  local needle="$2"
  if grep -Fq -- "$needle" "$file"; then
    echo "Expected file NOT to contain: $needle" >&2
    echo "  File: $file" >&2
    return 1
  fi
}

# Assert a file exists.
# Usage: assert_file_exists <path>
assert_file_exists() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "Expected file to exist: $file" >&2
    return 1
  fi
}

# Assert first pattern appears before second in a file.
# Usage: assert_line_order <file> <first> <second>
assert_line_order() {
  local file="$1"
  local first="$2"
  local second="$3"
  local first_line second_line
  first_line="$(grep -nF "$first" "$file" | head -1 | cut -d: -f1 || true)"
  second_line="$(grep -nF "$second" "$file" | head -1 | cut -d: -f1 || true)"
  if [[ -z "$first_line" || -z "$second_line" || "$first_line" -ge "$second_line" ]]; then
    echo "Expected '$first' (line ${first_line:-?}) before '$second' (line ${second_line:-?})" >&2
    echo "  File: $file" >&2
    return 1
  fi
}

# Assert a string/variable contains a substring.
# Usage: assert_contains <haystack> <needle>
assert_contains() {
  local haystack="$1"
  local needle="$2"
  if ! echo "$haystack" | grep -Fq -- "$needle"; then
    echo "Expected output to contain: $needle" >&2
    return 1
  fi
}

# Assert a string/variable does NOT contain a substring.
# Usage: assert_not_contains <haystack> <needle>
assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  if echo "$haystack" | grep -Fq -- "$needle"; then
    echo "Expected output NOT to contain: $needle" >&2
    return 1
  fi
}

# Assert a regex pattern matches within a file.
# Usage: assert_file_matches <file> <regex>
assert_file_matches() {
  local file="$1"
  local pattern="$2"
  if ! grep -qE "$pattern" "$file"; then
    echo "Expected file to match pattern: $pattern" >&2
    echo "  File: $file" >&2
    return 1
  fi
}
