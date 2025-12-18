#!/bin/bash
# Remove n8n-prod data directories
# WARNING: This will delete all workflows, credentials, execution history, AND PostgreSQL database

set -e

echo "WARNING: This will delete ALL n8n-prod data including PostgreSQL database!"
echo "Location: /mnt/zpool/Docker/Stacks/n8n-prod"
echo ""
echo "This includes:"
echo "  - All workflows"
echo "  - All credentials"
echo "  - All execution history"
echo "  - PostgreSQL database"
echo ""
read -p "Are you ABSOLUTELY sure? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cancelled."
    exit 1
fi

echo "Removing n8n-prod data directories..."
sudo rm -rf /mnt/zpool/Docker/Stacks/n8n-prod

echo "Done. Run ./build_stack_data.sh to recreate."
