#!/bin/bash
# Remove n8n-dev data directory
# WARNING: This will delete all workflows, credentials, and execution history

set -e

echo "WARNING: This will delete all n8n-dev data!"
echo "Location: /mnt/zpool/Docker/Stacks/n8n-dev"
read -p "Are you sure? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cancelled."
    exit 1
fi

echo "Removing n8n-dev data directory..."
sudo rm -rf /mnt/zpool/Docker/Stacks/n8n-dev

echo "Done. Run ./build_stack_data.sh to recreate."
