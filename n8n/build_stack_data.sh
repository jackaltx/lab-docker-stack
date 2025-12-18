#!/bin/bash
# Create n8n data directory on TrueNAS
# Note: n8n runs as UID 1000 internally (node user), doesn't respect PUID/PGID

ssh lavadmin@truenas.a0a0.org \
  "sudo mkdir -p /mnt/zpool/Docker/Stacks/n8n && \
   sudo chown -R 1000:1000 /mnt/zpool/Docker/Stacks/n8n"
