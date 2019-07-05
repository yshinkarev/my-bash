#!/bin/bash

# https://wiki.postgresql.org/wiki/Disk_Usage

FILENAME=$(basename "$0"); ONLYNAME=${FILENAME%.*}; LOG_FILE=/tmp/$ONLYNAME.log

if [ -z "$PSQL" ]; then
    PSQL=/usr/bin/psql
fi

echo "The largest databases in your cluster"
$PSQL --pset="pager=off" --pset="footer=off" --pset="border=2" --pset="format=wrapped" -c "SELECT d.datname AS Name,  pg_catalog.pg_get_userbyid(d.datdba) AS Owner, CASE WHEN pg_catalog.has_database_privilege(d.datname, 'CONNECT') THEN pg_catalog.pg_size_pretty(pg_catalog.pg_database_size(d.datname)) ELSE 'No Access'END AS SIZE FROM pg_catalog.pg_database d ORDER BY CASE WHEN pg_catalog.has_database_privilege(d.datname, 'CONNECT') THEN pg_catalog.pg_database_size(d.datname) ELSE NULL END DESC;" >> $LOG_FILE

echo "The size of your biggest relations"
$PSQL --pset="pager=off" --pset="footer=off" --pset="border=2" --pset="format=wrapped" -c "SELECT nspname || '.' || relname AS "relation", pg_size_pretty(pg_relation_size(C.oid)) AS "size" FROM pg_class C LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace) WHERE nspname NOT IN ('pg_catalog', 'information_schema') ORDER BY pg_relation_size(C.oid) DESC;" >> $LOG_FILE

echo "Table Size Information"
$PSQL --pset="pager=off" --pset="footer=off" --pset="border=2" --pset="format=wrapped" -c "SELECT *, pg_size_pretty(total_bytes) AS total, pg_size_pretty(index_bytes) AS INDEX, pg_size_pretty(toast_bytes) AS toast, pg_size_pretty(table_bytes) AS TABLE FROM (SELECT *, total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes FROM (SELECT c.oid, nspname                               AS table_schema, relname                               AS TABLE_NAME, c.reltuples                           AS row_estimate, pg_total_relation_size(c.oid)         AS total_bytes, pg_indexes_size(c.oid)                AS index_bytes, pg_total_relation_size(reltoastrelid) AS toast_bytes FROM pg_class c LEFT JOIN pg_namespace n ON n.oid = c.relnamespace WHERE relkind = 'r') a) a ORDER BY total DESC;" > $LOG_FILE

echo "The total size of your biggest tables"
$PSQL --pset="pager=off" --pset="footer=off" --pset="border=2" --pset="format=wrapped" -c "SELECT nspname || '.' || relname AS "relation", pg_size_pretty(pg_total_relation_size(C.oid)) AS "total_size" FROM pg_class C LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace) WHERE nspname NOT IN ('pg_catalog', 'information_schema')AND C.relkind <> 'i'AND nspname !~ '^pg_toast' ORDER BY pg_total_relation_size(C.oid) DESC;" >> $LOG_FILE

less -S  $LOG_FILE