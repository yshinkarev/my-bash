#!/usr/bin/env bash

PAGE_URL="https://www.thunderbird.net/en-US/thunderbird/all/"
SEARCH="os=linux64&lang=en-GB"
URL=$(curl -sS ${PAGE_URL} | grep ${SEARCH} | grep -Po '(?<=href=")[^"]*')

TEMP_FILE=$(mktemp /tmp/thunderbird.XXXXXX.tar.bz2)
wget "${URL}" -O "${TEMP_FILE}"
RC=$?
if [[ ${RC} != 0 ]]; then
    exit ${RC}
fi

sudo pkill thunderbird
sleep 1s

ROOT_DIR=/opt/inet
TARGET_DIR=${ROOT_DIR}/thunderbird
BACKUP_FILE=/tmp/thunderbird_bakup.tar
rm -rf ${BACKUP_FILE}
tar xf ${BACKUP_FILE} ${TARGET_DIR}

pv "${TEMP_FILE}" | sudo tar jxf - -C ${ROOT_DIR}
rm "${TEMP_FILE}"
sudo reset_perms_to_root.sh ${TARGET_DIR}