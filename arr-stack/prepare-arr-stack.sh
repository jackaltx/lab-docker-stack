#!/bin/bash
#
# prepare-arr-stack.sh
# Creates the minimal required directory structure for arr-stack deployment
#

set -euo pipefail

# Base paths
DOCKER_BASE="${DOCKER_BASE:-/mnt/zpool/Docker}"
MEDIA_BASE="${MEDIA_BASE:-/mnt/zpool/Media}"

STACK_DIR="${DOCKER_BASE}/Stacks/arr-stack"

echo "Creating arr-stack directory structure..."
echo "Docker base: ${DOCKER_BASE}"
echo "Media base: ${MEDIA_BASE}"
echo ""

# Create config directories
echo "Creating config directories..."
mkdir -p "${STACK_DIR}/gluetun"
mkdir -p "${STACK_DIR}/qbittorrent"
mkdir -p "${STACK_DIR}/sonarr/data"
mkdir -p "${STACK_DIR}/prowlarr/data"
mkdir -p "${STACK_DIR}/radarr"
mkdir -p "${STACK_DIR}/readarr/config"
mkdir -p "${STACK_DIR}/lidarr/config"
mkdir -p "${STACK_DIR}/bazarr"
mkdir -p "${STACK_DIR}/jellyseerr"

# Create media directories
echo "Creating media directories..."
mkdir -p "${MEDIA_BASE}/Downloads"
mkdir -p "${MEDIA_BASE}/Series"
mkdir -p "${MEDIA_BASE}/Movies"
mkdir -p "${MEDIA_BASE}/Books"
mkdir -p "${MEDIA_BASE}/Music"

echo ""
echo "Directory structure created successfully!"
echo ""
echo "Config directories:"
find "${STACK_DIR}" -type d | sort
echo ""
echo "Media directories:"
find "${MEDIA_BASE}" -type d | sort
