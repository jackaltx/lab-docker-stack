#!/bin/bash
#
# sync-env.sh
# Syncs variables from template file to stack .env files
# Only updates variables that already exist in target .env files
#
# Usage: sync-env.sh -f <template> [-p|-u]
#   -f <template>  Source template file (REQUIRED)
#   -p             Protect: Add .env files to .gitignore
#   -u             Unprotect: Remove .env files from .gitignore
#   -h             Show this help message
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Show help message
show_help() {
    cat << EOF
Usage: sync-env.sh -f <template> [-p|-u]

Syncs environment variables from a template file to all stack .env files.

Arguments:
  -f <template>  Source template file (REQUIRED)
                 Available: .env.global, a0a0.env, dockarr.env
  -p             Protect mode: Add **/.env to .gitignore
                 (prevents committing site-specific values)
  -u             Unprotect mode: Remove **/.env from .gitignore
                 (allows committing generic baseline)
  -h             Show this help message

Examples:
  # Switch to generic values for committing
  sync-env.sh -f .env.global -u

  # Switch to site-specific values for testing
  sync-env.sh -f a0a0.env -p

  # VM testing
  sync-env.sh -f dockarr.env -p

Workflow:
  - Generic work (committing): sync-env.sh -f .env.global -u
  - Site-specific work (testing): sync-env.sh -f {profile}.env -p

EOF
    exit 0
}

# Parse arguments
TEMPLATE_FILE=""
PROTECT_MODE=false
UNPROTECT_MODE=false

while getopts "f:puh" opt; do
    case $opt in
        f) TEMPLATE_FILE="$OPTARG" ;;
        p) PROTECT_MODE=true ;;
        u) UNPROTECT_MODE=true ;;
        h) show_help ;;
        \?) echo "Invalid option. Use -h for help."; exit 1 ;;
    esac
done

# Validate -f is provided
if [[ -z "$TEMPLATE_FILE" ]]; then
    echo "Error: -f <template_file> is required"
    echo ""
    echo "Usage: sync-env.sh -f <template> [-p|-u]"
    echo "Available templates: .env.global, a0a0.env, dockarr.env"
    echo ""
    echo "Use -h for full help"
    exit 1
fi

# Validate -p and -u not used together
if [[ "$PROTECT_MODE" == true && "$UNPROTECT_MODE" == true ]]; then
    echo "Error: Cannot use -p and -u together"
    exit 1
fi

# Validate template exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "Error: Template file not found: $TEMPLATE_FILE"
    exit 1
fi

# Source the template
source "$TEMPLATE_FILE"

# Extract variable names from template file
SYNC_VARS=()
while IFS='=' read -r key value || [[ -n "$key" ]]; do
    # Skip empty lines and comments
    [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
    # Strip leading/trailing whitespace from key
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"
    # Add to array if not empty
    [[ -n "$key" ]] && SYNC_VARS+=("$key")
done < "$TEMPLATE_FILE"

# Auto-discover target directories (containing both compose.yaml/yml and .env)
TARGETS=()
for dir in */; do
    dir="${dir%/}"
    if [[ (-f "${dir}/compose.yaml" || -f "${dir}/compose.yml") && -f "${dir}/.env" ]]; then
        TARGETS+=("$dir")
    fi
done

echo "Syncing from $TEMPLATE_FILE to stack .env files..."
echo ""

for target in "${TARGETS[@]}"; do
    env_file="${SCRIPT_DIR}/${target}/.env"

    if [[ ! -f "$env_file" ]]; then
        echo "Warning: $env_file not found, skipping"
        continue
    fi

    echo "Processing: $target/.env"

    for var in "${SYNC_VARS[@]}"; do
        # Check if variable exists in target .env
        if grep -q "^${var}=" "$env_file"; then
            # Get value from template (using indirect expansion)
            value="${!var:-}"
            if [[ -n "$value" ]]; then
                echo "  - Updating ${var}=${value}"
                sed -i "s|^${var}=.*|${var}=${value}|" "$env_file"
            else
                echo "  - Skipping ${var} (not set in template)"
            fi
        fi
    done
    echo ""
done

echo "Sync complete!"
echo ""

# Handle .gitignore protection/unprotection
GITIGNORE="${SCRIPT_DIR}/.gitignore"

if [[ "$PROTECT_MODE" == true ]]; then
    if ! grep -q "^\*\*/\.env$" "$GITIGNORE" 2>/dev/null; then
        echo "" >> "$GITIGNORE"
        echo "# Protect .env files from commits (added by sync-env.sh -p)" >> "$GITIGNORE"
        echo "**/.env" >> "$GITIGNORE"
        echo "✓ Protected: .env files added to .gitignore"
    else
        echo "✓ Already protected: .env files already in .gitignore"
    fi
fi

if [[ "$UNPROTECT_MODE" == true ]]; then
    if grep -q "^\*\*/\.env$" "$GITIGNORE" 2>/dev/null; then
        # Remove the line and the comment before it
        sed -i '/^# Protect \.env files/d; /^\*\*\/\.env$/d' "$GITIGNORE"
        echo "✓ Unprotected: .env files removed from .gitignore"
    else
        echo "✓ Already unprotected: .env files not in .gitignore"
    fi
fi
