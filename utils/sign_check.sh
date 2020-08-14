#!/usr/bin/env bash

SIGN=$1
FILENAME=$2
TYPE=$3

if [ -z "$SIGN" ]; then
	>&2 echo "Missing SIGNATURE"
	exit 1
fi

if [ -z "$FILENAME" ]; then
	>&2 echo "Missing FILENAME"
	exit 1
fi

if [ -z "$TYPE" ]; then
	>&2 echo "Missing TYPE (md5, sha256)"
	exit 1
fi

LO_TYPE=$(echo $TYPE | tr A-Z a-z)

case "$LO_TYPE" in
	sha256) echo "$SIGN *$FILENAME" | sha256sum -c -
	    ;;
	md5)  echo "$SIGN *$FILENAME" | md5sum -c -
	    ;;
	*) >&2 echo "Unsupported type $TYPE"
	   exit 1
	   ;;
esac