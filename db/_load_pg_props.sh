#!/usr/bin/env bash

if [ -z "${DB_PROP_FILE}" ]; then
    DB_PROP_FILE=$(dirname "$0")/db.properties
fi
if [ ! -f ${DB_PROP_FILE} ]; then
    >&2 echo "Missing DB properties file"
    exit 1
fi
source ${DB_PROP_FILE}