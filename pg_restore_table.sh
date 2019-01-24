#!/bin/bash

FILE_NAME=$1
if [ -z "$FILE_NAME" ]; then
	>&2 echo "Missing argument: [FILE NAME]"
	exit 1
fi
shift 1

pg_restore --clean $FILE_NAME