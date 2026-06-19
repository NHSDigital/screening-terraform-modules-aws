#!/usr/bin/env bash
# Run all bats test suites for screening-terraform-modules-aws.
#
# Usage:
#   bash tests/run-all-tests.sh            # Standard TAP output
#   bash tests/run-all-tests.sh --pretty   # Pretty-printed output (if available)
#
# Prerequisites:
#   bats-core (managed via mise; see .tool-versions)

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT" || exit 1

if ! command -v bats &>/dev/null; then
  echo "ERROR: bats-core is not installed. Run 'mise install' to set up tools." >&2
  exit 1
fi

echo "======================================================================"
echo "Running bats test suites"
echo "======================================================================"
echo ""

bats_args=()

# Use pretty formatter if available and terminal is interactive
if [[ "${1:-}" == "--pretty" ]] || [[ -t 1 && "${1:-}" != "--tap" ]]; then
  bats_args+=(--formatter pretty)
fi

exec bats "${bats_args[@]}" tests/*.bats
