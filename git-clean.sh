#!/bin/bash

INIT_DIR=$(pwd)
DIRECTORY=

set -e
function cleanup {
	cd $INIT_DIR > /dev/null
}
trap cleanup EXIT

########################################

gitClean() {
	git reflog expire --all --expire=now
	git gc --prune=now --aggressive
}

########################################

for arg in "$@"; do
	  case $arg in
	    --directory=*)
	  	DIRECTORY=${arg#*=}
	  	;;
	    *)
	      echo "Unknown argument: $arg"
	      # help
	      exit 1
	      ;;
	  esac
	done

########################################

if [ -z "$DIRECTORY" ]; then
	gitClean
else
	for dir in $(find $DIRECTORY -type d -iname .git); do
		target="${dir%.git}"
		echo "***** Clean $target *****"
		cd $target
		gitClean
	done
fi