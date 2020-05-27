#!/usr/bin/env bash

TABLE_NAME=$1
if [ -z "$TABLE_NAME" ]; then
	read -p "Enter table name: " TABLE_NAME
fi

CSV_FILE_NAME=$(echo "$TABLE_NAME" | sed -e 's/[^A-Za-z0-9_-]/_/g').csv
$(dirname "$0")/psql -c "\COPY $TABLE_NAME TO $CSV_FILE_NAME CSV HEADER"
FSIZE=$(stat -c%s "$CSV_FILE_NAME"); HSIZE=$(numfmt --to=iec-i --suffix=B --format="%.1f" $FSIZE);
echo "$CSV_FILE_NAME: $HSIZE"