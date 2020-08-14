#!/usr/bin/env bash

FILE=$1
if [ -z "$FILE" ]; then
	FILE=MD5SUMS
fi

find -type f -name "*.iso" -exec md5sum "{}" + > $FILE