#!/bin/bash

if [ -z "$1" ]; then
	>&2 echo "Missing directory"
	exit 1
fi

dirName=$(basename "$1")
dir=$1
shift 1

if [ ! -d "$dir" ]; then
	>&2 echo "No such directory"
	exit 1
fi

excludeSize=

for arg in "$@"; do
	  case $arg in
	    --directory=*)
	    	targetDir=${arg#*=}
	    	;;
	    --exclude-size=*)
		excludeSize=${arg#*=}
	    	;;
	    *)
	      >&2 echo "Unknown argument: $arg"
	      exit 1
	      ;;
	  esac
	done

if [ -z "$targetDir" ]; then
	targetDir=.
else
	shift 1
fi

targetPath=$targetDir/$dirName-$(date +"%Y.%m.%d_%H-%M-%S").tar.gz
echo "$dir -> $targetPath"

if [ -z "$excludeSize" ]; then
	tar hcf - "$dir" | /home/schumi/bin/compress/pigz -9 --quiet --keep --recursive --rsyncable $@ - > $targetPath
else
	tar hcf - "$dir" --exclude-from <(find -L $dir -size $excludeSize) | /home/schumi/bin/compress/pigz -9 --quiet --keep --recursive --rsyncable - > $targetPath
fi
