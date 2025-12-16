#!/bin/bash
# build_stack_data.sh - Auto-create data directories from compose.yaml
# Parses Docker Compose volume mappings and creates required directories

set -e

# Script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="$(basename "$SCRIPT_DIR")"

# Parse arguments
DRY_RUN=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            echo "Usage: $0 [--dry-run]"
            echo "  --dry-run  Preview directories without creating them"
            exit 0
            ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Source .env file
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
else
    echo "ERROR: .env file not found in $SCRIPT_DIR"
    exit 1
fi

# Validate required variables
if [ -z "$DOCKER_ROOT" ]; then
    echo "ERROR: DOCKER_ROOT not set in .env"
    exit 1
fi

# Determine if path is a file mapping
is_file_mapping() {
    local path="$1"

    # Check for file extensions
    if [[ "$path" =~ \.(yml|yaml|log|conf|json|xml|txt|toml|ini)$ ]]; then
        return 0  # Is a file
    fi

    # Check for known file names
    if [[ "$path" =~ /(traefik\.yml|access\.log|config\.yml)$ ]]; then
        return 0  # Is a file
    fi

    return 1  # Is a directory
}

# Create or preview directory
create_dir() {
    local dir_path="$1"

    # Expand variables
    dir_path=$(eval echo "$dir_path")

    if is_file_mapping "$dir_path"; then
        echo "ERROR: File mapping detected: $dir_path"
        echo "File mappings not yet supported. Will handle in next phase."
        exit 1
    fi

    if [ "$DRY_RUN" = true ]; then
        # Dry run mode - check if exists
        if [ -d "$dir_path" ]; then
            echo "[EXISTS] $dir_path"
        else
            echo "[WOULD CREATE] $dir_path"
        fi
    else
        # Actually create
        echo "Creating: $dir_path"
        mkdir -p "$dir_path"
    fi
}

# Parse compose.yaml and extract Stacks volumes
parse_and_create() {
    local compose_file="$SCRIPT_DIR/compose.yaml"

    if [ ! -f "$compose_file" ]; then
        echo "ERROR: compose.yaml not found in $SCRIPT_DIR"
        exit 1
    fi

    # Extract volume mappings from compose.yaml
    # Look for lines like: - ${DOCKER_ROOT}/Stacks/...:/container/path
    local volumes_found=false

    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue

        # Match volume lines with ${DOCKER_ROOT}/Stacks/
        if [[ "$line" =~ -[[:space:]]+[\"\']\?\$\{DOCKER_ROOT\}/Stacks/([^:\"\']+) ]]; then
            local host_path="${BASH_REMATCH[0]}"
            # Clean up the path
            host_path=$(echo "$host_path" | sed 's/^-[[:space:]]*//' | sed 's/:.*//' | tr -d '"' | tr -d "'")

            # Skip if it's a read-only mount
            if [[ "$line" =~ :ro[[:space:]]*$ ]]; then
                continue
            fi

            # Skip parent directory mounts (arcane special case)
            if [[ "$host_path" =~ \$\{DOCKER_ROOT\}/Projects ]] || [[ "$host_path" =~ \$\{DOCKER_ROOT\}/Stacks[[:space:]]*: ]]; then
                continue
            fi

            volumes_found=true
            create_dir "$host_path"
        fi
    done < "$compose_file"

    if [ "$volumes_found" = false ]; then
        echo "No data volumes found for this service."
    fi
}

# Main
main() {
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Building data directories for: $PROJECT_NAME"
    else
        echo "Building data directories for: $PROJECT_NAME"
    fi
    echo "DOCKER_ROOT: $DOCKER_ROOT"
    echo ""

    parse_and_create

    echo ""
    echo "Done!"
}

main "$@"
