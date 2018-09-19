#!/bin/bash

# https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip
URL=$1
if [ -z "$URL" ]; then
    >&2 echo "Missing argument: https link (zip archive)"
    exit 1
fi

ZIP_FILENAME=$(basename $URL)
echo "=========== Downloading $ZIP_FILENAME ==========="
ZIP_FILEPATH=$(mktemp /tmp/$ZIP_FILENAME.XXXXXX)
wget $URL -O $ZIP_FILEPATH
RC=$?  
if [ $RC -ne 0 ]; then
	exit $RC
fi

echo "=========== Extracting archive $ZIP_FILEPATH ==========="
ANDROID_DIR=android-sdk-linux
mkdir $ANDROID_DIR
cd $ANDROID_DIR
unzip -q $ZIP_FILEPATH
RC=$?  
if [ $RC -ne 0 ]; then
	exit $RC
fi

echo "=========== Installing SDK ==========="
./tools/bin/sdkmanager "platform-tools"

cd .. > /dev/null