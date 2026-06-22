#!/usr/bin/env bash
################################################################################
# Generate "Available modules" section for README.md
#
# Reads module metadata from generate-available-modules.yaml and generates
# a markdown table of available modules for insertion into README.md.
# The metadata file is the source of truth for descriptions and wrapped modules.
#
# Preserves the README's custom content and updates only the modules table
# between explicit markers.
#
# Usage:
#   ./scripts/generate-available-modules.sh [output_file]
#
# Arguments:
#   output_file (optional): Path to write the generated section
#                          (default: README.md)
#
# Exit codes:
#   0 - Success
#   1 - Failed to generate content
#
################################################################################

set -uo pipefail

# ============================================================================
# Configuration
# ============================================================================
repo_root="$(git rev-parse --show-toplevel)"
output_file="${1:-README.md}"
# Handle absolute paths (if output_file starts with /, use as-is; otherwise prepend repo_root)
if [[ "${output_file}" = /* ]]; then
    readme_file="${output_file}"
else
    readme_file="${repo_root}/${output_file}"
fi
metadata_file="${repo_root}/scripts/config/generate-available-modules.yaml"
modules_dir="${repo_root}/infrastructure/modules"

# Markers for the auto-generated section
begin_marker="<!-- BEGIN_AVAILABLE_MODULES -->"
end_marker="<!-- END_AVAILABLE_MODULES -->"

# Colors for output
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
nc='\033[0m'

# ============================================================================
# Validation
# ============================================================================
if [ ! -f "${metadata_file}" ]; then
    printf "${red}✗ Error: Metadata file not found at ${metadata_file}${nc}\n" >&2
    exit 1
fi

if [ ! -d "${modules_dir}" ]; then
    printf "${red}✗ Error: modules directory not found at ${modules_dir}${nc}\n" >&2
    exit 1
fi

if [ ! -f "${readme_file}" ]; then
    printf "${red}✗ Error: README file not found at ${readme_file}${nc}\n" >&2
    exit 1
fi

if ! grep -q "${begin_marker}" "${readme_file}"; then
    printf "${red}✗ Error: missing marker '${begin_marker}' in ${readme_file}${nc}\n" >&2
    printf "  Add the following markers to README.md:\n" >&2
    printf "    ${begin_marker}\n" >&2
    printf "    (table will be inserted here)\n" >&2
    printf "    ${end_marker}\n" >&2
    exit 1
fi

if ! grep -q "${end_marker}" "${readme_file}"; then
    printf "${red}✗ Error: missing marker '${end_marker}' in ${readme_file}${nc}\n" >&2
    exit 1
fi

# ============================================================================
# Generate modules table from metadata
# ============================================================================
printf "Scanning modules and reading metadata...\n" >&2

temp_table=$(mktemp)
trap 'rm -f "${temp_table}"' EXIT

# Write table header (only the table, not the heading - that's already in README)
cat > "${temp_table}" << 'TABLE_HEADER'
| Module | Wraps | Description |
| --- | --- | --- |
TABLE_HEADER

module_count=0

# Process each module that exists in infrastructure/modules
while IFS= read -r module_dir; do
    module_name=$(basename "${module_dir}")

    # Skip special directories
    if [ "${module_name}" = "_legacy" ] || [ "${module_name}" = ".gitkeep" ]; then
        continue
    fi

    # Check if module has metadata entry
    if ! grep -q "^${module_name}:" "${metadata_file}"; then
        printf "  ${yellow}⚠${nc}  No metadata for: ${module_name} (skipping)\n" >&2
        continue
    fi

    printf "  Processing: ${module_name}\n" >&2

    # Extract description and wraps from metadata using simple grep/sed
    # This approach works without requiring yq/jq
    description=$(sed -n "/^${module_name}:/,/^[a-z]/p" "${metadata_file}" | \
                  grep "description:" | \
                  sed 's/.*description: *"//;s/".*//')

    # Get the wraps field
    wraps=$(sed -n "/^${module_name}:/,/^[a-z]/p" "${metadata_file}" | \
            grep "wraps:" | \
            sed 's/.*wraps: *"//;s/".*//')

    # Fallback if extraction failed
    if [ -z "${description}" ]; then
        description="(no description)"
    fi

    if [ -z "${wraps}" ]; then
        wraps="—"
    fi

    # Write table row
    printf "| \`%s\` | %s | %s |\n" "${module_name}" "${wraps}" "${description}" >> "${temp_table}"

    ((module_count++))
done < <(find "${modules_dir}" -maxdepth 1 -type d | grep -v "^\.$" | sort)

if [ ${module_count} -eq 0 ]; then
    printf "${red}✗ Error: no modules with metadata found${nc}\n" >&2
    exit 1
fi

printf "${green}✓${nc} Generated table for ${module_count} modules\n" >&2

# ============================================================================
# Replace section in README
# ============================================================================
temp_readme=$(mktemp)
trap 'rm -f "${temp_table}" "${temp_readme}"' EXIT

awk \
    -v begin="${begin_marker}" \
    -v end="${end_marker}" \
    -v table_file="${temp_table}" '
BEGIN {
    in_section = 0
}
{
    if ($0 ~ begin) {
        in_section = 1
        print $0
        while ((getline line < table_file) > 0) {
            print line
        }
        close(table_file)
    } else if ($0 ~ end) {
        in_section = 0
        print ""
        print $0
    } else if (!in_section) {
        print $0
    }
}
' "${readme_file}" > "${temp_readme}"

# Replace original
cp "${temp_readme}" "${readme_file}"

printf "${green}✓${nc} Updated: ${readme_file}\n" >&2
exit 0
