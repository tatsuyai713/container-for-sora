#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
cd $SCRIPT_DIR

NAME_IMAGE="sora-container-for-${USER}"
DOCKER_NAME="sora-for-${USER}"

CONTAINER_ID=$(docker ps -a | grep ${NAME_IMAGE} | awk '{print $1}')


docker start $CONTAINER_ID
docker exec -it $CONTAINER_ID /bin/bash