#!/bin/bash
# https://dev.mysql.com/doc/refman/5.7/en/resetting-permissions.html

read -p "Enter table name: " TABLE_NAME
# John,Smith,....
read -p "Enter raw query result: " RAW_QUERY

COLUMNS=$(psql -Ac "select * from $TABLE_NAME where false;" $@ | head -n 1)
IFS='|' read -ra COLUMNS_ARRAY <<< "$COLUMNS"
IFS=',' read -ra ARGUMENTS_ARRAY <<< "$RAW_QUERY"

if [ ${#COLUMNS_ARRAY[@]} != ${#ARGUMENTS_ARRAY[@]} ]; then
	>&2 echo "Illegal arguments size"
	echo "Columns: $COLUMNS"
	echo "Query: $RAW_QUERY"
	exit 1;
fi

for i in "${!COLUMNS_ARRAY[@]}"; do 	
	printf "%-20s = %s\n" ${COLUMNS_ARRAY[$i]} ${ARGUMENTS_ARRAY[$i]}
done