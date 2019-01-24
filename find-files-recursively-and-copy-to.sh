#!/bin/bash

FILENAME_PATTERN=
SRC_DIR=./
DEST_DIR=./
QUIET=0

########################################

for arg in "$@"; do
	  case $arg in
	    --filename=*)
	    	FILENAME_PATTERN=${arg#*=}
	    	shift 1
	    	;;
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

if [ -z "$FILENAME_PATTERN" ]; then
	>&2 echo "Missing argument: FILENAME PATTERN (--filename)"
	exit 1
fi

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