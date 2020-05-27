#!/usr/bin/env bash

# Generate from one PNG file images for android directories drawable-*.

PNG_FILE=$1
if [ -z "$PNG_FILE" ]; then
    >&2 echo "Missing argument: file name (png)"
    exit 1
fi

FILE_NAME=$(basename "$PNG_FILE"); EXT="${PNG_FILE##*.}"; FILE_NAME="${FILE_NAME%.*}"

declare -a names=("hdpi" "mdpi" "xhdpi" "xxhdpi" "xxxhdpi")
declare -a sizes=(36 24 48 72 96)
# declare -a sizes=(18 12 24 36 48)

for ((i = 0; i < ${#names[@]}; ++i)); do
	NAME=${names[$i]}
	SIZE=${sizes[$i]};
	DIR=drawable-$NAME
	mkdir -p $DIR
	convert $PNG_FILE -resize $SIZE'x'$SIZE $DIR/$FILE_NAME.$EXT
done

# find ./ -iname "*.png" -exec android_gen_drawables.sh {} \;