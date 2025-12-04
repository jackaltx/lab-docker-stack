#!/bin/bash
#
# sync-env.sh
# Syncs variables from .env.global to stack .env files
# Only updates variables that already exist in target .env files
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_ENV="${SCRIPT_DIR}/.env.global"

# Check if .env.global exists
if [[ ! -f "$GLOBAL_ENV" ]]; then
    echo "Error: .env.global not found at $GLOBAL_ENV"
    exit 1
fi

# Source .env.global
source "$GLOBAL_ENV"

# List of variables to sync
SYNC_VARS=("PUID" "PGID" "TZ" "DOMAIN" "DOCKER_ROOT" "MEDIA_ROOT")

# Target directories
TARGETS=("freshrss" "traefik3" "arcane" "gitea" "homarr" "jellyfin" "minio")

echo "Syncing from .env.global to stack .env files..."
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
            # Get value from .env.global (using indirect expansion)
            value="${!var:-}"
            if [[ -n "$value" ]]; then
                echo "  - Updating ${var}=${value}"
                sed -i "s|^${var}=.*|${var}=${value}|" "$env_file"
            else
                echo "  - Skipping ${var} (not set in .env.global)"
            fi
        fi
    done
    echo ""
done

echo "Sync complete!"
