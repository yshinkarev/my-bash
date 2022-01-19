#!/usr/bin/env bash

INIT_DIR=$(pwd)
DIRECTORY=$1

set -e
function cleanup {
	if [ -n "$DIRECTORY" ]; then
		cd $INIT_DIR > /dev/null
	fi
}

if [ -n "$DIRECTORY" ]; then
	cd $DIRECTORY
fi

if [ "$(uname)" == "Darwin" ]; then
    du -h -d 1 2> >(grep -v 'cannot access') | sort -hr
else
	du -a -h --max-depth=1 2> >(grep -v 'cannot access') | sort -hr
fi