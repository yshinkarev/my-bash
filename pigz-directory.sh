#!/bin/bash

if [ -z "$1" ]; then
	>&2 echo "Missing directory"
	exit 1
fi

DIRNAME=$(basename "$1")
DIR=$1
shift 1

if [ ! -d "$DIR" ]; then
	>&2 echo "No such directory"
	exit 1
fi

EXCLUDESIZE=
PREFIX=

for arg in "$@"; do
	  case $arg in
	    --directory=*)
	    	TARGETDIR=${arg#*=}
	    	shift
	    	;;
	    --exclude-size=*)
		EXCLUDESIZE=${arg#*=}
		shift
	    	;;
	    --prefix=*)
		PREFIX=${arg#*=}
		shift
	    	;;
	    *)
	      >&2 echo "Unknown argument: $arg"
	      exit 1
	      ;;
	  esac
	done

if [ -z "$TARGETDIR" ]; then
	TARGETDIR=.
fi

if [ -z "$PREFIX" ]; then
	PREFIX=$DIRNAME-
fi

targetPath=$TARGETDIR/$PREFIX$(date +"%Y.%m.%d_%H-%M-%S").tar.gz
echo "$DIR -> $targetPath"

if [ -z "$EXCLUDESIZE" ]; then
	tar hcf - "$DIR" | pigz -9 --quiet --keep --recursive --rsyncable $@ - > $targetPath
else
	tar hcf - "$DIR" --exclude-from <(find -L $DIR -size $EXCLUDESIZE) | pigz -9 --quiet --keep --recursive --rsyncable - > $targetPath
fi