#!/bin/bash

which ffmpeg >/dev/null
if [ $? -ne 0 ]; then
	>&2 echo "ffmpeg must be installed before running this script."
	exit 1
fi

########################################

convert() {	
	DEST_FILE="${1%.*}"; DEST_FILE=$DEST_FILE.mkv
	echo "$1 -> $DEST_FILE"
	ffmpeg -hide_banner -i $1 $DEST_FILE
}

########################################

SRC_FILE=$1

if [ -z "$SRC_FILE" ]; then
	for FILE in *.mp4; do
		echo
		convert $FILE
	done
else	
	convert $SRC_FILE	
fi