#!/bin/bash

if [ ! -d ".git" ]; then
	>&2 echo "Directory .git not found"
	exit 1
fi

git branch -r --format='%(authorname)|%(refname:short)|%(committerdate:iso)' | column -s\| -t