#!/bin/bash

help() {
cat << EOF
Show specific line of file in branch
Usage: BRANCH FILENAME LINE_NUMBER [GIT_REPOSITORY_DIR]
	BRANCH                  Git branch, for example orgin/master
	FILENAME                Target filename. Can only name without relative path
	LINE_NUMBER             Target line number of file
	GIT_REPOSITORY_DIR      Location of git repository. Default is current directory
	--help			print this help
EOF
}

if [[ "$@" == *"--help"* ]]; then
	help
	exit 0
fi

if [ "$#" -lt 3 ]; then
	help
	exit 1
fi

# Path.
gitDir=./

if [ "$#" -gt 3 ]; then
	gitDir=$3
fi

paths=($(find $gitDir -name "$2" -type f))
findFiles=${#paths[@]}

if [ $findFiles == 0 ]; then
	>&2 echo "File $2 not found"
	exit 1
fi

if [ $findFiles -gt 1 ]; then
	>&2 echo "Find $findFiles files, but expected only one"
	printf "  %s\n" "${paths[@]}"
	exit 1
fi

git show $1:${paths[0]} | sed -n $3p