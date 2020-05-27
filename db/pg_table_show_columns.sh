#!/usr/bin/env bash
# https://dev.mysql.com/doc/refman/5.7/en/resetting-permissions.html

TABLE_NAME=$1
if [ -z "$TABLE_NAME" ]; then
	>&2 echo "Missing argument: [TABLE NAME]"
	exit 1
fi
shift 1

$(dirname "$0")/psql -Ac "select * from $TABLE_NAME where false;" $@ | head -n 1