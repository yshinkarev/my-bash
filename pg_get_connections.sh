#!/bin/bash

DB_NAME=$1
if [ -z $DB_NAME ]; then
	>&2 echo "Missing argument DB_NAME"
	exit 1
fi

$(dirname "$0")/psql --pset="pager=off" --pset="footer=off" --pset="border=2" --pset="format=wrapped" -c "SELECT pid, usename, application_name, client_addr, client_port, date_trunc('second', backend_start) AS backend_start, wait_event, state, LEFT(query, 80) AS query FROM pg_stat_activity WHERE datname = '$DB_NAME'"