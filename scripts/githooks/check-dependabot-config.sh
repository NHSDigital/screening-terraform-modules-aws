#!/usr/bin/env bash
################################################################################
# Pre-commit hook: Check and regenerate Dependabot configuration
#
# This hook runs the Dependabot configuration generator and ensures the
# result matches the committed configuration. If they differ, it regenerates
# the config and fails the pre-commit, forcing the user to review and commit
# the updated configuration.
#
# Trigger: When any versions.tf file in infrastructure/modules changes
#
# Exit codes:
#   0 - Config is up-to-date
#   1 - Config was regenerated (user must review and commit)
#   2 - Error
#
################################################################################

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
generator="${repo_root}/scripts/generate-dependabot-config.sh"
config_file="${repo_root}/.github/dependabot.yaml"
temp_config=$(mktemp)

# Colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
nc='\033[0m'

# shellcheck disable=SC2329 # Invoked via trap on script exit.
cleanup() {
    rm -f "${temp_config}"
}
trap cleanup EXIT

# Validate generator exists
if [ ! -f "${generator}" ]; then
    printf "${red}✗ Error: Generator not found at ${generator}${nc}\n" >&2
    exit 2
fi

# Generate fresh config
if ! bash "${generator}" "${temp_config}" > /dev/null 2>&1; then
    printf "${red}✗ Error: Failed to generate Dependabot configuration${nc}\n" >&2
    exit 2
fi

# Compare with current config
if [ ! -f "${config_file}" ]; then
    printf "${red}✗ Error: Current config not found at ${config_file}${nc}\n" >&2
    printf "  Please run: scripts/generate-dependabot-config.sh\n" >&2
    exit 2
fi

if diff -q "${config_file}" "${temp_config}" > /dev/null 2>&1; then
    # Configs match
    printf "${green}✓${nc} Dependabot configuration is up-to-date\n" >&2
    exit 0
else
    # Configs differ - update and fail
    printf "${yellow}⚠${nc}  Dependabot configuration is out of date\n" >&2
    printf "   Regenerating: ${config_file}\n" >&2

    cp "${temp_config}" "${config_file}"

    printf "\n${red}✗ Pre-commit check FAILED - Config was regenerated${nc}\n" >&2
    printf "\nPlease review the updated configuration and commit it:\n" >&2
    printf "  git add .github/dependabot.yaml\n" >&2
    printf "  git commit -m 'chore: update Dependabot configuration'\n" >&2
    printf "\nChanges made:\n" >&2
    diff "${config_file}" "${temp_config}" || true

    exit 1
fi
