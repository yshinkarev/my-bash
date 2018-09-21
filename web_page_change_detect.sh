#!/bin/bash

URL=$1
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
