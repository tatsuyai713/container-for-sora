#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
cd $SCRIPT_DIR

if [ $# -ne 1 ]; then
	echo "Usage: $0 <password>"
	exit 1
fi
PASSWORD=$1

NAME_IMAGE="sora-container-for-${USER}"
DOCKER_NAME="sora-for-${USER}"

XAUTH=/tmp/.docker.xauth
touch $XAUTH
xauth_list=$(xauth nlist :0 | sed -e 's/^..../ffff/')
if [ ! -z "$xauth_list" ]; then
	echo $xauth_list | xauth -f $XAUTH nmerge -
fi
chmod a+r $XAUTH

DOCKER_OPT=""
DOCKER_WORK_DIR="/home/${USER}"
KERNEL=$(uname -r)

## For XWindow
DOCKER_OPT="${DOCKER_OPT} \
	--env=QT_X11_NO_MITSHM=1 \
    --volume=/tmp/.X11-unix:/tmp/.X11-unix:rw \
	--volume=/home/${USER}:/home/${USER}:rw \
	--env=XAUTHORITY=${XAUTH} \
	--env=TERM=xterm-256color \
	--volume=${XAUTH}:${XAUTH} \
	--env=DISPLAY=${DISPLAY} \
	-w ${DOCKER_WORK_DIR} \
	-u ${USER} \
	--shm-size=4096m \
	--tmpfs /dev/shm:rw \
	-p 3$(id -u):8088 \
	-p 4$(id -u):80 \
	--hostname $(hostname)-Docker \
	--add-host $(hostname)-Docker:127.0.1.1"

## Allow X11 Connection
xhost +local:$(hostname)-Docker

DOCKER_OPT="${DOCKER_OPT} --gpus all "
docker run -it ${DOCKER_OPT} \
	--name=${DOCKER_NAME} \
	--rm \
	-e PASSWD=${PASSWORD} \
	-e SSL_ENABLE=${SSL_ENABLE} -e CERT_PATH="/home/$USER/ssl/" \
	--entrypoint "/usr/bin/supervisord" \
	${NAME_IMAGE}:latest

xhost -local:$(hostname)-Docker
