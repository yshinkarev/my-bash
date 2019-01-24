#!/bin/bash

which ffmpeg >/dev/null
if [ $? -ne 0 ]; then
	>&2 echo "ffmpeg must be installed before running this script."
	exit 1
fi

SRC=./*.mp3
DEST=./result.mp3

########################################

for arg in "$@"; do
	  case $arg in
	    --source=*)
	    	SRC=${arg#*=}
	    	shift 1
	    	;;
	    --dest=*)
	    	DEST=${arg#*=}
	    	shift 1
	    	;;
	    *)
	      >&2 echo "Unknown argument: $arg"
	      exit 1
	      ;;	    	
	  esac
	done

########################################

NAME=$(basename "$0")
NAME="${NAME%.*}"
TMP_LIST_FILE=$(mktemp /tmp/$NAME.XXX)
echo $TMP_LIST_FILE

find $SRC -type f -print0 | while IFS= read -r -d $'\0' FILE; do
	echo "file '$(readlink -e $FILE)'" >> $TMP_LIST_FILE;
done

if [[ ! -s "$TMP_LIST_FILE" ]]; then 	
	exit 1
fi

ffmpeg -hide_banner -f concat -safe 0 -i $TMP_LIST_FILE -c copy $DEST $@
exit $?