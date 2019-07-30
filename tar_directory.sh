#!/bin/bash

if [ -z "$1" ]; then
    echo >&2 "Missing directory"
    exit 1
fi

if [ ! -d "$1" ]; then
    echo >&2 "No such directory"
    exit 1
fi

shopt -s nullglob dotglob
files=($1/*)
if [ ${#files[@]} -eq 0 ]; then
    echo "Warning. Directory has no files"
fi

DIR_NAME=$(basename "$1")
TARGET_NAME=${DIR_NAME}-$(date +"%Y.%m.%d_%H-%M-%S").tar
tar -hC "$(dirname "$1")" -cf "${TARGET_NAME}" "${DIR_NAME}"
