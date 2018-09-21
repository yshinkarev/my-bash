#!/bin/bash

HASH_ONLY=0
URL=

#####################################################
for arg in "$@"; do
	case $arg in
	    --hash-only)
	  	HASH_ONLY=1	  	
	  	shift
	  	;;
	    --url=*)
	  	URL=${arg#*=}
	  	shift
	  	;;
	  esac
done
#####################################################

if [ -z "$URL" ]; then
	URL_FILE=${0%.*}.url	
	if [ -f $URL_FILE ]; then
		URL=$(<$URL_FILE)
	fi
fi
if [ -z "$URL" ]; then	
	>&2 echo "Missing argument: URL"
	exit 1
fi

#####################################################
getPageSha() {
OUTPUT=$(curl -sL "$URL")
OUTPUT=$(echo "$OUTPUT" | grep --invert-match "readcount")
echo -n "$OUTPUT" | sha512sum | awk '{ print $1 }'
}
#####################################################

PREV=$(getPageSha)
if [ $HASH_ONLY = 1 ]; then
	echo "$PREV"
	exit 0
fi

exit 0

REQUESTS=1
START=$(date +%s)
for (( ; ; )); do
	sleep 5m	
	CURRENT=$(getPageSha)
	REQUESTS=$((REQUESTS + 1))
	if [ "$PREV" != "$CURRENT" ]; then
		END=$(date +%s)
		DIFF=$(( $END - $START ))
		MSG="Page changed. Total requests $REQUESTS. Job Time $(($DIFF / 60))m"
		echo "$MSG"
		notify-send "$MSG"
		beep.sh
		exit 0
	fi
done
