#!/bin/bash

URL=$1
if [ -z "$URL" ]; then
	echo "Missing argument: URL"
	exit 1
fi

# TODO: process non 200 status
LENGTH=$(curl -sI $URL | grep Content-Length | awk '{print $2}' | tr -d '\r')

if [[ "$@" == *"--human"* ]]; then
	LENGTH=$(numfmt --to=iec-i --suffix=B --format="%.3f" $LENGTH)
fi

echo "$LENGTH"