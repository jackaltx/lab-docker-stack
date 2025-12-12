#!/bin/bash
source .env

mkdir -p "${DOCKER_ROOT}/Stacks/jellyfin/config"
mkdir -p "${DOCKER_ROOT}/Stacks/jellyfin/cache"

# I already create these..adjust to your media storageneeds
#
# mkdir -p "${MEDIA_ROOT}/movies"
# mkdir -p "${MEDIA_ROOT}/music"
# mkdir -p "${MEDIA_ROOT}/series"
# mkdir -p "${MEDIA_ROOT}/music-lessons"