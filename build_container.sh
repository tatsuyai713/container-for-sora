#!/bin/bash

NAME_IMAGE="sora-container-for-${USER}"
DOCKER_NAME="sora-for-${USER}"

echo "Build Container"

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
cd $SCRIPT_DIR
cd ./files/


# Make Container
if [ ! "$(docker image ls -q ${NAME_IMAGE})" ]; then
	if [ "$http_proxy" ]; then
		echo "Image ${NAME_IMAGE} does not exist."
		echo 'Now building US image with proxy...'
		docker build --file=./user_proxy.dockerfile -t $NAME_IMAGE . --build-arg UID=$(id -u) --build-arg GID=$(id -g) --build-arg UNAME=$USER --build-arg IN_LOCALE='US' --build-arg IN_TZ='UTC' --build-arg IN_LANG='en_US.UTF-8' --build-arg IN_LANGUAGE='en_US:en' --build-arg HTTP_PROXY=$http_proxy --build-arg HTTPS_PROXY=$https_proxy
	else
		echo "Image ${NAME_IMAGE} does not exist."
		echo 'Now building US image without proxy...'
		docker build --file=./user.dockerfile -t $NAME_IMAGE . --build-arg UID=$(id -u) --build-arg GID=$(id -g) --build-arg UNAME=$USER --build-arg IN_LOCALE='US' --build-arg IN_TZ='UTC' --build-arg IN_LANG='en_US.UTF-8' --build-arg IN_LANGUAGE='en_US:en'
	fi

fi