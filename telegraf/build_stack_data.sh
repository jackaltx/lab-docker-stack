#!/bin/bash
source .env
mkdir -p "${DOCKER_ROOT}/Stacks/telegraf"
cp ./telegraf.conf "${DOCKER_ROOT}/Stacks/telegraf/telegraf.conf"
