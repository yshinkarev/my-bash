#!/bin/bash

URL=$1
if [ -z "$URL" ]; then
	>&2 echo "Missing argument NEW URL"
	exit 1
fi

git remote set-url origin --add $URL
git push -u origin --all
git push -u origin --tags