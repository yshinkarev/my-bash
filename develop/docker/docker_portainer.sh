#!/usr/bin/env bash

# https://www.portainer.io/installation
# https://hub.docker.com/r/portainer/portainer
VOLUME_NAME=portainer_data
CONTAINER_NAME=portainer

if [[ "$1" == "up" ]]; then
    docker volume create ${VOLUME_NAME}
    docker run -d --name=${CONTAINER_NAME} --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer
    exit 1
fi

if [[ "$1" == "down" ]]; then
    docker rm --force --volumes ${CONTAINER_NAME}
    docker volume rm ${VOLUME_NAME}
    exit 1
fi

echo >&2 "Missing argument: up or down"
