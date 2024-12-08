#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
cd $SCRIPT_DIR

NAME_IMAGE="sora-container-for-${USER}"
DOCKER_NAME="sora-for-${USER}"

# Delete
echo 'Now stopping docker container...'
CONTAINER_ID=$(docker ps -a | grep ${DOCKER_NAME} | awk '{print $1}')
docker stop $CONTAINER_ID