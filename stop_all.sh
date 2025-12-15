#!/bin/bash
# stop_all.sh - Stop all Docker Compose stacks (except those with .noauto)

# Color output for better visibility
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "=== Docker Compose Auto-Stop ==="
echo ""

# Find and stop all compose files (except traefik3, save it for last)
find . -type f \( -name "compose.yaml" -o -name "compose.yml" -o -name "docker-compose.yaml" -o -name "docker-compose.yml" \) | while read -r compose_file; do
    dir=$(dirname "$compose_file")
    project_name=$(basename "$dir")

    # Skip traefik3 (stop it last)
    if [ "$project_name" = "traefik3" ]; then
        continue
    fi

    # Check for .noauto file
    if [ -f "$dir/.noauto" ]; then
        echo -e "${YELLOW}[SKIP]${NC} $project_name (has .noauto file)"
        continue
    fi

    echo -e "${GREEN}[STOP]${NC} $project_name"
    if (cd "$dir" && docker compose down); then
        echo -e "${GREEN}✓${NC} $project_name stopped successfully"
    else
        echo -e "${RED}✗${NC} $project_name failed to stop"
    fi
    echo ""
done

# Stop Traefik last (reverse proxy should go down after services)
if [ -f "./traefik3/compose.yaml" ] && [ ! -f "./traefik3/.noauto" ]; then
    echo -e "${GREEN}[LAST]${NC} traefik3 (reverse proxy)"
    if (cd "./traefik3" && docker compose down); then
        echo -e "${GREEN}✓${NC} traefik3 stopped successfully"
    else
        echo -e "${RED}✗${NC} traefik3 failed to stop"
    fi
    echo ""
fi

echo "Done."
