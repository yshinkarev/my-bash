#!/bin/bash

excludeSize=
path=$1
shift 1

for arg in "$@"; do
	  case $arg in
	    --exclude-size=*)
		excludeSize=${arg#*=}
	    	;;
	    *)
	      >&2 echo "Unknown argument: $arg"
	      exit 1
	      ;;
	  esac
	done

for dir in $path*
do
	archive=$(basename "$dir")-$(date +"%Y.%m.%d_%H-%M-%S").tar.gz
	echo "Compress $dir to $archive"

	if [ -z "$excludeSize" ]; then
		tar cfh - "$dir" | pigz -9 --quiet --keep --recursive --rsyncable > $archive
	else
		tar cfh - "$dir" --exclude-from <(find -L $dir -size $excludeSize) | pigz -9 --quiet --keep --recursive --rsyncable > $archive
	fi
done