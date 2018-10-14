#!/bin/bash

URL=https://telegram.org/dl/desktop/linux
TARGET_DIR=$1
if [ -z "$TARGET_DIR" ]; then
	TARGET_DIR=/opt/inet/messengers
fi

TEMP_FILE=$(mktemp /tmp/telegram.XXXXXX.tar.xz)
wget $URL --output-document=$TEMP_FILE
RC=$?;
if [[ $RC != 0 ]]; then
	exit $RC;
fi

sudo pkill -f Telegram
pv $TEMP_FILE | sudo tar Jkxf - -C $TARGET_DIR --overwrite
rm $TEMP_FILE
sudo reset-perms-to-root.sh $TARGET_DIR
