#!/bin/bash

if [ -z "$1" ]; then
	>&2 echo "Missing directory"
	exit 1
fi

if [ ! -d "$1" ]; then
	>&2 echo "No such directory"
	exit 1
fi

shopt -s nullglob dotglob
files=($1/*)
if [ ${#files[@]} -eq 0 ];
	then echo "Warning. Directory has no files";
fi

dirName=$(basename "$1")
targetName=$dirName-$(date +"%Y.%m.%d_%H-%M-%S").tar
tar -hC "$(dirname "$1")" -cf $targetName "$dirName"