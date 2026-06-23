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
# Helper Functions
# ============================================================================

# Check if a directory name should be skipped entirely
is_special_directory() {
    local dir_name="$1"

    # Skip empty names only
    [ -z "${dir_name}" ] && return 0

    return 1
}

# Check if a module is in the legacy directory
is_legacy_module() {
    local module_path="$1"
    [[ "${module_path}" =~ _legacy ]] && return 0
    return 1
}

# ============================================================================
# Generate modules table from metadata
# ============================================================================
printf "Scanning modules and reading metadata...\n" >&2

temp_table=$(mktemp)
temp_modules=$(mktemp)
temp_readme=$(mktemp)
trap 'rm -f "${temp_table}" "${temp_modules}" "${temp_readme}"' EXIT

# Write table header (only the table, not the heading - that's already in README)
cat > "${temp_table}" << 'TABLE_HEADER'
| Module | Wraps | Description |
| --- | --- | --- |
TABLE_HEADER

# Find all actual modules by looking for main.tf or versions.tf files
# Store relative paths so we can detect legacy modules
# Exclude .terraform directories and collect unique module directories
# Prepend sort key: 0 for regular modules, 1 for legacy (ensures legacy modules appear at end)
find "${modules_dir}" -maxdepth 2 \( -name "main.tf" -o -name "versions.tf" \) ! -path "*/.terraform/*" -print | \
    while read -r file; do
        # Get relative path from modules_dir, then the parent directory
        rel_dir=$(dirname "${file#${modules_dir}/}")
        module_name=$(basename "${rel_dir}")
        # Determine sort key: 0 for regular modules, 1 for legacy
        if [[ "${rel_dir}" =~ _legacy ]]; then
            sort_key=1
        else
            sort_key=0
        fi
        # Output sort_key|relative_path|module_name
        echo "${sort_key}|${rel_dir}|${module_name}"
    done | sort -t'|' -k1,1 -k3,3 -u > "${temp_modules}"

module_count=0

# Process each module found in the filesystem, with legacy modules at the end
while IFS='|' read -r sort_key module_path module_name; do
    # Skip special directories
    if is_special_directory "${module_name}"; then
        continue
    fi

    # Check if this module is in the legacy directory
    legacy_indicator=""
    if is_legacy_module "${module_path}"; then
        legacy_indicator=" [LEGACY]"
    fi

    printf "  Processing: ${module_name}${legacy_indicator}\n" >&2

    # Check if module has metadata entry
    if grep -q "^${module_name}:" "${metadata_file}"; then
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
            description="—"
        fi

        if [ -z "${wraps}" ]; then
            wraps="—"
        fi
    else
        # Module found but not in metadata - use dashes
        printf "    ${yellow}⚠${nc}  No metadata entry (using dashes)\n" >&2
        description="—"
        wraps="—"
    fi

    # Append legacy indicator to description if applicable
    if [ -n "${legacy_indicator}" ]; then
        if [ "${description}" = "—" ]; then
            description="[LEGACY]"
        else
            description="${description} [LEGACY]"
        fi
    fi

    # Write table row
    printf "| \`%s\`%s | %s | %s |\n" "${module_name}" "${legacy_indicator}" "${wraps}" "${description}" >> "${temp_table}"

    ((module_count++))
done < "${temp_modules}"

if [ ${module_count} -eq 0 ]; then
    printf "${red}✗ Error: no modules found (missing main.tf or versions.tf files)${nc}\n" >&2
    exit 1
fi

printf "${green}✓${nc} Generated table for ${module_count} modules\n" >&2

# ============================================================================
# Replace section in README
# ============================================================================

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
