#!/bin/bash

DIRECTORY=$1

if [ -z "$DIRECTORY" ]; then
	>&2 echo "Missing DIRECTORY"
	exit 1
fi

chown root:root -R $DIRECTORY
chmod og-w -R $DIRECTORY