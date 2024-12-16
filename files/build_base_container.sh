#!/bin/bash

NAME_IMAGE="sora-container"
echo "Build Base Container"

docker build -f common.dockerfile -t  ghcr.io/tatsuyai713/${NAME_IMAGE}:v0.03 .
docker push  ghcr.io/tatsuyai713/${NAME_IMAGE}:v0.03
