#!/usr/bin/env bash

set -e

if [ "$1" == "--help" ]; then
    echo "$(basename "$0") CONTAINER_NAME IMAGE_NAME VOLUME_MOUNT_POINT [VOLUME_NAME]"
fi

CONTAINER_NAME=$1
[ -z "${CONTAINER_NAME}" ] && echo >&2 "Missing argument: container name" && exit 1
shift

if [ "$1" == "--remove" ]; then
    shift
    VOLUME_NAME=$1
    [ -z "${VOLUME_NAME}" ] && VOLUME_NAME="${CONTAINER_NAME}_data"
    printf "Remove container ... "
    docker container rm ${CONTAINER_NAME} --force --volumes
    printf "Remove volume ... "
    docker volume rm ${VOLUME_NAME}
    exit 0
fi

IMAGE=$1
[ -z "${IMAGE}" ] && echo >&2 "Missing argument: image name" && exit 1
shift

VOLUME_MOUNT_POINT=$1
[ -z "${VOLUME_MOUNT_POINT}" ] && echo >&2 "Missing argument: volume mount point" && exit 1
shift
VOLUME_NAME=$1
if [ -z "${VOLUME_NAME}" ]; then
    VOLUME_NAME="${CONTAINER_NAME}_data"
else
    shift
fi

printf "Create volume ... "
docker volume create ${VOLUME_NAME}

printf "Create container ... "
docker create --name ${CONTAINER_NAME} \
    -v ${VOLUME_NAME}:${VOLUME_MOUNT_POINT} \
    --restart unless-stopped \
    "$@" \
    ${IMAGE}

printf "Start container ... "
docker start ${CONTAINER_NAME}
