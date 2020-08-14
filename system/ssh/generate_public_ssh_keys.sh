#!/usr/bin/env bash

PUBLIC_DIR=public
mkdir -p ${PUBLIC_DIR}

OIFS="$IFS"
IFS=$'\n'
for FILE in $(find . -type f 2>/dev/null); do
    ssh-keygen -y -f ${FILE} > ${PUBLIC_DIR}/"${FILE}".pub
done
IFS="$OIFS"