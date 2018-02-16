#!/bin/bash

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

du -a -h --max-depth=1 | sort -hr