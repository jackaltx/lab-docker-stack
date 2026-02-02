#!/bin/bash
source .env
mkdir -p "${DOCKER_ROOT}/Stacks/conduit/db"

# Generate conduit.toml with actual values
sed "s/CONDUIT_HOST_PLACEHOLDER/${CONDUIT_HOST}/g; s/DOMAIN_PLACEHOLDER/${DOMAIN}/g" \
    conduit.toml > "${DOCKER_ROOT}/Stacks/conduit/conduit.toml"

echo "Generated ${DOCKER_ROOT}/Stacks/conduit/conduit.toml with server_name=${CONDUIT_HOST}.${DOMAIN}"
