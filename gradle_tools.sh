#!/bin/bash

INIT_DIR=$(pwd)
DIRECTORY=.
CMD=
FILENAME=$(basename "$0"); ONLYNAME=${FILENAME%.*}; LOG_FILE=/tmp/$ONLYNAME.log

set -e
function cleanup {
	cd $INIT_DIR > /dev/null
}
trap cleanup EXIT

########################################

showHelp() {
cat << EOF
Usage: $(basename $0) [--directory=DIR] [--cmd=COMMAND][--help]
Run gradle recursively for all projects in directory DIR and all subdirectories.

  --directory   Start directory to search (default: current directory)
  --cmd         Command. Available: build, clean
  --help        Show this help and exit
EOF
}

########################################

gradleClean() {
	gradle clean
	rm -rf .gradle
}

########################################

gradleBuild() {
	gradle build
}

########################################

execCommand() {
case "$CMD" in
	clean)
		gradleClean
	    	;;
	build)
		gradleBuild
		;;
esac
}

########################################

if [[ "$@" == *"--help"* ]]; then
	showHelp
	exit 0
fi

for arg in "$@"; do
	  case $arg in
	    --directory=*)
	  	DIRECTORY=${arg#*=}
	  	shift
	  	;;
	    --cmd=*)
	  	CMD=${arg#*=}
	  	shift
	  	;;
	    *)
	      echo "Unknown argument: $arg"
	      # help
	      exit 1
	      ;;
	  esac
	done

########################################

if [ "$CMD" != "clean" ] && [ "$CMD" != "build" ] ; then
	>&2 echo "Unexpected argument cmd"
	showHelp
	exit 1
fi

rm -f $LOG_FILE
exec > >(tee -ia $LOG_FILE)
exec 2>&1

if [ -z "$DIRECTORY" ]; then
	execCommand
else
	for dir in $(find $DIRECTORY -type d -iname gradle); do
		TARGET="$(dirname "$dir")"
		echo "*************** $TARGET ***************"
		cd $TARGET
		execCommand
		cd - > /dev/null
	done || exit 1
fi