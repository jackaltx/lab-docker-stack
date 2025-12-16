#!/bin/bash
# deploy_all.sh - Deploy all Docker Compose stacks (except those with .noauto)

# Color output for better visibility
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "=== Docker Compose Auto-Deploy ==="
echo ""

# Deploy Traefik first (creates required networks)
if [ -f "./traefik3/compose.yaml" ] && [ ! -f "./traefik3/.noauto" ]; then
    echo -e "${BLUE}[FIRST]${NC} traefik3 (creates networks)"
    if (cd "./traefik3" && docker compose up -d); then
        echo -e "${GREEN}✓${NC} traefik3 deployed successfully"
    else
        echo -e "${RED}✗${NC} traefik3 failed to deploy (continuing anyway)"
    fi
    echo ""
fi

# Find and deploy all other compose files
find . -type f \( -name "compose.yaml" -o -name "compose.yml" -o -name "docker-compose.yaml" -o -name "docker-compose.yml" \) | while read -r compose_file; do
    dir=$(dirname "$compose_file")
    project_name=$(basename "$dir")

    # Skip traefik3 (already deployed)
    if [ "$project_name" = "traefik3" ]; then
        continue
    fi

    # Check for .noauto file
    if [ -f "$dir/.noauto" ]; then
        echo -e "${YELLOW}[SKIP]${NC} $project_name (has .noauto file)"
        continue
    fi

    echo -e "${GREEN}[DEPLOY]${NC} $project_name"
    if (cd "$dir" && docker compose up -d); then
        echo -e "${GREEN}✓${NC} $project_name deployed successfully"
    else
        echo -e "${RED}✗${NC} $project_name failed to deploy"
    fi
    echo ""
done

echo "Done."
