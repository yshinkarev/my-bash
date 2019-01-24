#!/bin/bash

if [ "$#" -ne 1 ]; then
	>&2 echo "Missing directory"
	exit 1
fi

find $1 -type f -print0 | xargs -0 sed -i 's/\s*$//'