#!/bin/bash
source .env
#
mkdir -p "${DOCKER_ROOT}/Stacks/traefik/acme"
mkdir -p "${DOCKER_ROOT}/Stacks/traefik/log"
cp ./configs/traefik-access-log.yml "${DOCKER_ROOT}/Stacks/traefik/traefik.yml"
