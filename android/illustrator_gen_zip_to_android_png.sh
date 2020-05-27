#!/usr/bin/env bash

ZIPFILE=$1
if [ -z "$ZIPFILE" ]; then
    >&2 echo "Missing argument: file name (zip archive)"
    exit 1
fi

DEBUG=0
if [[ "$@" == *"--debug"* ]]; then
	DEBUG=1
fi

if [ ! -f $ZIPFILE ]; then
	>&2 echo "File not exists $ZIPFILE"
	exit 1
fi

tmpDir=$(mktemp --directory --quiet)
if [ $DEBUG == 1 ]; then
	echo "Create temp directory: $tmpDir"
fi

if [ $DEBUG == 1 ]; then
	echo "Extract zip $ZIPFILE to temp directory"
fi
unzip -q $ZIPFILE -d $tmpDir
rc=$?;
if [[ $rc != 0 ]]; then
	>&2 echo "Unexpected exists [1]: $rc"
	exit $rc;
fi

filename=$(basename "$ZIPFILE")
iconName=$(echo "${filename%.*}" | awk '{print tolower($0)}')

declare -a names=("hdpi" "mdpi" "xhdpi" "xxhdpi" "xxxhdpi")
for name in "${names[@]}"
do
	sourceFile=$(find $tmpDir -type d -name "*-$name")

	if [ -z "$sourceFile" ]; then
		>&2 echo "Missing resolution: $name"
		exit 1
	fi

	targetDir="drawable-$name"
	mkdir -p $targetDir
	if [ $DEBUG == 1 ]; then
		echo "Create directory: $targetDir"
	fi

	targetFile=$targetDir/$iconName.png
	if [ $DEBUG == 1 ]; then
		echo "Copy $sourceFile to $targetFile"
	fi
	mv "$sourceFile" "$targetFile"

	rc=$?;
	if [[ $rc != 0 ]]; then
		>&2 echo "Unexpected exists [2]: $rc"
		exit $rc;
	fi
done

if [ $DEBUG == 1 ]; then
	echo "Remove temp directory: $tmpDir"
fi
rm -rf $tmpDir