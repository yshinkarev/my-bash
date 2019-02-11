#!/bin/bash

DIR=.
TO_JPG=0
NAME=
ADD_TIMESTAMP=0

########################################

showHelp() {
cat << EOF
Usage: $(basename $0) [--directory=DIR] [--mask=MASK] [--format=FORMAT] [--help]
Rename all files with mask MASK in directory DIR to file name with timestamp FORMAT

  --directory   Directory to search
  --mask        Files mask
  --format      Timestamp format
  --help        Show this help and exit
EOF
}

########################################

if [[ "$@" == *"--help"* ]]; then
	showHelp
	exit 0
fi

for arg in "$@"; do
	  case $arg in
	    --directory=*)
	    	DIR=${arg#*=}
	    	;;
	    --name=*)
	    	NAME=${arg#*=}
	    	;;
	    --to-jpg|-tj)
	    	TO_JPG=1
	    	;;
	    --add-timestamp|-at)
	    	ADD_TIMESTAMP=1
	    	;;
	    *)
	      >&2 echo "Unknown argument: $arg"
	      exit 1
	      ;;
	  esac
	done

if [ -z "$NAME" ]; then
	NAME=$(adb shell getprop ro.product.model)
	NAME=${NAME::-1}
	NAME=$(echo "${NAME//[$'\t\r\n ']/-}")
fi

PTH=$DIR/$NAME

if [ $ADD_TIMESTAMP == 1 ]; then
	PTH="$PTH"_$(date +"%Y-%m-%d_%H-%M-%S")
fi

FILE_NAME="$PTH".png
adb shell screencap -p | sed 's/\r$//' > $FILE_NAME

FINAL_FILE_NAME=$FILE_NAME
if [ $TO_JPG == 1 ]; then
	FINAL_FILE_NAME="$PTH".jpg
	convert $FILE_NAME $FINAL_FILE_NAME
	rm $FILE_NAME
fi

echo "$FINAL_FILE_NAME"