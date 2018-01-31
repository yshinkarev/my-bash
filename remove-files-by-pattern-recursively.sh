#!/bin/bash

FILES=$1
if [ -z "$FILES" ]; then
	>&2 echo "Missing argument: files pattern"
	exit 1
fi

find . -name "$FILES" -type f -delete