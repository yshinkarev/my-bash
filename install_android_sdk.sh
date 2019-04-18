#!/bin/bash

# https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip
URL=$1
if [[ -z "${URL}" ]]; then
    >&2 echo "Missing argument: https link (zip archive)"
    exit 1
fi

ZIP_FILENAME=$(basename ${URL})
ZIP_FILEPATH=$(mktemp /tmp/${ZIP_FILENAME}.XXXXXX)

set -e
function cleanup {
	[[ -e ${ZIP_FILEPATH} ]] && rm ${ZIP_FILEPATH}
}
trap cleanup EXIT


echo "=========== Downloading $ZIP_FILENAME ==========="
wget ${URL} -O ${ZIP_FILEPATH}
RC=$?
if [[ ${RC} -ne 0 ]]; then
	exit ${RC}
fi

echo "=========== Extracting archive $ZIP_FILEPATH ==========="
ANDROID_DIR=android-sdk-linux
mkdir ${ANDROID_DIR}
cd ${ANDROID_DIR}
unzip -q ${ZIP_FILEPATH}
RC=$?
if [[ ${RC} -ne 0 ]]; then
	exit ${RC}
fi

echo "=========== Installing SDK ==========="
./tools/bin/sdkmanager "platform-tools"

cd .. > /dev/null