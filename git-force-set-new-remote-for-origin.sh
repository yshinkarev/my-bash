#!/bin/bash

URL=$1
if [ -z "$URL" ]; then
	>&2 echo "Missing argument NEW URL"
	exit 1
fi

git remote remove origin
git remote add origin $URL
git fetch
git branch --set-upstream-to=origin/master master
git pull --rebase