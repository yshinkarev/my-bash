#!/usr/bin/env bash

URL=$1
if [ -z "$URL" ]; then
	>&2 echo "Missing URL"
	exit 1
fi

# Download file.
wget $URL
rc=$?;
if [[ $rc != 0 ]]; then
	exit $rc;
fi

# Check sign.
SIGN_TYPE=$2
if [ -z "$SIGN_TYPE" ]; then
	exit 0
fi

SIGN=$3
if [ -z "$SIGN" ]; then
	>&2 echo "Missing SIGNATURE"
	exit 1
fi

FILENAME=$(basename "$URL")
LO_TYPE=$(echo $SIGN_TYPE | tr A-Z a-z)

echo "Check file signature."
case "$LO_TYPE" in
	sha256) echo "$SIGN *$FILENAME" | sha256sum -c -
	    ;;
	md5)  echo "$SIGN *$FILENAME" | md5sum -c -
	    ;;
	*) >&2 echo "Unsupported type $SIGN_TYPE"
	   exit 1
	   ;;
esac