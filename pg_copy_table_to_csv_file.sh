#!/bin/bash

TABLE_NAME=$1
if [ -z "$TABLE_NAME" ]; then
	>&2 echo "Missing argument: [TABLE NAME]"
	exit 1
fi

FILE=$2
if [ -z "$FILE" ]; then
	FILE=$TABLE_NAME.csv
fi

psql -t -A -F"," -c "SELECT * FROM $TABLE_NAME" > $FILE