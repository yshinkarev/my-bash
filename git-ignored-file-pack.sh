#!/bin/bash

DIRECTORY=$1
if [ -z "$DIRECTORY" ]; then
	>&2 echo "Missing argument DIRECTORY"
	exit 1
fi

ARCHIVE_FILE_NAME=$PWD/$(basename $DIRECTORY).tar.gz
cd $DIRECTORY
git ls-files --others --ignored --exclude-standard | tar -cf $ARCHIVE_FILE_NAME -I pigz -T -
cd - > /dev/null