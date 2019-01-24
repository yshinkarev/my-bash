#!/bin/bash

FILENAME_PATTERN=
SRC_DIR=./
DEST_DIR=./
QUIET=0

########################################

showHelp() {
cat << EOF
Usage: $(basename $0) FNAME_PATTERN [--source=SRC_DIR] [--dest=TARGET_DIR] [--quiet] [--help]
Find recursively all files by pattern FNAME_PATTERN and copy to current or specific directory

  --source      Start directory to search. Default current directory
  --dest        Target directory to copy files. Default current directory
  --quiet       Do not output any information at all
  --help        Show this help and exit
EOF
}

########################################

if [[ "$@" == *"--help"* ]]; then
	showHelp
	exit 0
fi

FILENAME_PATTERN=$1
shift 1
if [ -z "$FILENAME_PATTERN" ]; then
	>&2 echo "Missing argument: FNAME_PATTERN"
	exit 1
fi

for arg in "$@"; do
	  case $arg in
	    --source=*)
	    	SRC_DIR=${arg#*=}
	    	shift 1
	    	;;
	    --dest=*)
	    	DEST_DIR=${arg#*=}
	    	shift 1
	    	;;
	    --quiet)
	    	QUIET=1
	    	shift 1
	    	;;
 	    --help)
		showHelp
		exit 0
		;;
	    *)
	      >&2 echo "Unknown argument: $arg"
	      exit 1
	      ;;
	  esac
	done

########################################

locEcho() {
	if [ $QUIET == 0 ]; then
		echo $@
	fi
}

########################################

TOTAL=0
ERRORS=0

# May be issue with whitespace at filenames.
while read FILE
do
	FILENAME=$(basename "$FILE")
	if [ $QUIET == 0 ]; then
		printf "%s - " $FILENAME
	fi


	RET=$(cp $FILE $DEST_DIR)
	if [ -z "$RET" ]; then
		locEcho "OK"
	else
		locEcho $RET
		ERRORS=$(($ERRORS + 1))
	fi

	((++TOTAL))
done <<< "$(find $SRC_DIR -type f -name "$FILENAME_PATTERN")"

echo "Total files proccessed: $TOTAL. Errors: $ERRORS"