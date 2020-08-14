#!/usr/bin/env bash

FILE=$1
if [ -z "${FILE}" ]; then
    echo >&2 "Missing file"
    exit 1
fi

SKIP=$(awk '/^__TARFILE_FOLLOWS__/ { print NR + 1; exit 0; }' "${FILE}")
[ $? -ne 0 ] && return 1
echo "Skip bytes: ${SKIP}"

# Now no support only bzip2.
tail -n +${SKIP} ${FILE} | tar -xj