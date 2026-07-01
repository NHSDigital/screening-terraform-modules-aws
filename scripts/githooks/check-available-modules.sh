#!/usr/bin/env bash
################################################################################
# Pre-commit hook: Check and regenerate available modules section in README
#
# This hook runs the available modules generator and ensures the result
# matches the committed README. If they differ, it regenerates the section
# and fails the pre-commit, forcing the user to review and commit the updated
# documentation.
#
# Trigger: When any README.md in infrastructure/modules changes, or when
#          module directories are added/removed
#
# Exit codes:
#   0 - Section is up-to-date
#   1 - Section was regenerated (user must review and commit)
#   2 - Error
#
################################################################################

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
generator="${repo_root}/scripts/generate-available-modules.sh"
readme_file="${repo_root}/README.md"
temp_readme=$(mktemp)

# Colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
nc='\033[0m'

# shellcheck disable=SC2329 # Invoked via trap on script exit.
cleanup() {
    rm -f "${temp_readme}"
}
trap cleanup EXIT

# Validate generator exists
if [ ! -f "${generator}" ]; then
    printf "${red}✗ Error: Generator not found at ${generator}${nc}\n" >&2
    exit 2
fi

# Create a temp copy of the current README
if ! cp "${readme_file}" "${temp_readme}" 2>/dev/null; then
    printf "${red}✗ Error: Failed to copy README${nc}\n" >&2
    exit 2
fi

# Run generator on the temp copy
if ! bash "${generator}" "${temp_readme}" > /dev/null 2>&1; then
    printf "${red}✗ Error: Failed to generate available modules section${nc}\n" >&2
    exit 2
fi

# Compare the original README with the regenerated temp README
if diff -q "${readme_file}" "${temp_readme}" > /dev/null 2>&1; then
    # READMEs match - section is up-to-date
    printf "${green}✓${nc} Available modules section is up-to-date\n" >&2
    exit 0
else
    # READMEs differ - regenerate the original and fail
    printf "${yellow}⚠${nc}  Available modules section is out of date\n" >&2
    printf "   Regenerating: ${readme_file}\n" >&2

    # Generate fresh content directly to the original file
    if ! bash "${generator}" > /dev/null 2>&1; then
        printf "${red}✗ Error: Failed to regenerate section${nc}\n" >&2
        exit 2
    fi

    printf "\n${red}✗ Pre-commit check FAILED - README was regenerated${nc}\n" >&2
    printf "\nPlease review the updated Available modules section and commit it:\n" >&2
    printf "  git add README.md\n" >&2
    printf "  git commit -m 'docs: update Available modules section'\n" >&2

    exit 1
fi
