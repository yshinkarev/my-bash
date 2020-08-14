#!/usr/bin/env bash

JAR=$1
if [ -z "${JAR}" ]; then
    echo >&2 "Missing argument: jar file"
    exit 1
fi

if [ ! -f "${JAR}" ]; then
	    echo >&2 echo "File ${JAR} not found"
	    exit 1
	fi

BIN=${JAR%.*}

echo '#!/usr/bin/env bash
MYSELF=`which "$0" 2>/dev/null`
[ $? -gt 0 -a -f "$0" ] && MYSELF="./$0"
java=java
if test -n "$JAVA_HOME"; then
    java="$JAVA_HOME/bin/java"
fi
exec "$java" $java_args -jar $MYSELF "$@"
exit 1 ' >$BIN

cat $JAR >>$BIN
chmod +x $BIN
echo $BIN