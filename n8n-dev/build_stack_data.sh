#!/bin/bash
# Create n8n-dev data directory on TrueNAS
# Note: n8n runs as UID 1000 internally (node user), doesn't respect PUID/PGID

# this runs locally

sudo mkdir -p /mnt/zpool/Docker/Stacks/n8n-dev/data && \
sudo chown -R 1000:1000 /mnt/zpool/Docker/Stacks/n8n-dev
