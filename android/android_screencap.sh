#!/usr/bin/env bash

DIR=.
TO_JPG=0
NAME=
ADD_TIMESTAMP=0

########################################

showHelp() {
    cat <<EOF
Usage: $(basename $0) [OPTIONS]
Make screenshot from android device using screencap

  -d,  --directory      Output directory
  -n,  --name           Output filename
  -tj, --to-jpg         Auto convert screenshot to jpeg format
  -at, --add-timestamp  Add filename suffix with current timestamp
  -h,  --help           Show this help and exit
EOF
}

########################################

if [[ "$@" == *"--help"* ]] || [[ "$@" == *"-h"* ]]; then
    showHelp
    exit 0
fi

for arg in "$@"; do
    case $arg in
    --directory=*)
        DIR=${arg#*=}
        ;;
    -d=*)
        DIR=${arg#*=}
        ;;
    -n=*)
        NAME=${arg#*=}
        ;;
    --name=*)
        NAME=${arg#*=}
        ;;
    --to-jpg | -tj)
        TO_JPG=1
        ;;
    --add-timestamp | -at)
        ADD_TIMESTAMP=1
        ;;
    *)
        echo >&2 "Unknown argument: $arg"
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
# adb shell screencap -p | sed 's/\r$//' > $FILE_NAME
# adb shell screencap -p >$FILE_NAME
adb exec-out screencap -p  > $FILE_NAME

FINAL_FILE_NAME=$FILE_NAME
if [ $TO_JPG == 1 ]; then
    FINAL_FILE_NAME="$PTH".jpg
    convert $FILE_NAME $FINAL_FILE_NAME
    rm $FILE_NAME
fi

echo "$FINAL_FILE_NAME"
