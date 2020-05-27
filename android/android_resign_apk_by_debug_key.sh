#!/usr/bin/env bash
TARGET=$1
[ -z "${TARGET}" ] && echo >&2 "Missing argument: apk file" && exit 1
EXTENSION="${TARGET##*.}"
NAME="${TARGET%.*}"

TMP_FILE=$(mktemp /tmp/"${NAME}".XXXXXX)

set -e
function cleanup() {
    rm -f ${TMP_FILE} >/dev/null
}
trap cleanup EXIT

cp ${TARGET} ${TMP_FILE}
zip --delete ${TMP_FILE} 'META-INF/*'
jarsigner -verbose -keystore ~/.android/debug.keystore -storepass android -keypass android ${TMP_FILE} androiddebugkey -signedjar ${NAME}-signed.${EXTENSION}
