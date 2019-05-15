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

SRC_FILE=
FORMAT=mp4
DIR=.

for arg in "$@"; do
	case $arg in
	    --dir=*)
	  	DIR=${arg#*=}
	  	shift
	  	;;
	    --format=*)
	  	FORMAT=${arg#*=}
	  	shift
	  	;;
	    --src=*)
	  	SRC_FILE=${arg#*=}
	  	shift
	  	;;
	  esac
	done

########################################

if [ -z "$SRC_FILE" ]; then
	for FILE in $DIR/*.$FORMAT; do
		echo
		convert $FILE
	done
else
	convert $SRC_FILE
fi

beep.sh