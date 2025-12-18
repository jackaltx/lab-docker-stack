#!/bin/bash
# Create n8n-prod data directories
# Note: n8n runs as UID 1000, PostgreSQL runs as UID 999 (both set internally)

# Runs locally - adjust DOCKER_ROOT path as needed for your environment

sudo mkdir -p /mnt/zpool/Docker/Stacks/n8n-prod/{data,postgres} && \
sudo chown -R 1000:1000 /mnt/zpool/Docker/Stacks/n8n-prod
