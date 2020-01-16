#!/bin/bash

TABLE_NAME=$1
if [[ -z "$TABLE_NAME" ]]; then
    echo >&2 "Missing argument: [TABLE NAME]"
    exit 1
fi
shift 1

$(dirname "$0")/pg_dump --format=custom --table="${TABLE_NAME}" --compress=9 >"${TABLE_NAME}".pg