#!/bin/bash

humanFormat() {
	echo $(numfmt --to=iec-i --suffix=B --format="%.1f" $1)
}

FILE=~/.bash_history
SIZE_BEFORE=$(humanFormat $(stat -c%s "$FILE"))
TMP_FILE=$(mktemp history.XXX)

# Remove duplicates.
awk '!seen[$0]++' $FILE > $TMP_FILE

mv $FILE $FILE.bak
mv $TMP_FILE $FILE
rm -f $TMP_FILE

# Sort file.
sort $FILE -o $FILE

# Remove whitespaces.
sed -i 's/\s*$//' $FILE

SIZE_AFTER=$(humanFormat $(stat -c%s "$FILE"))
echo "$FILE processed: $SIZE_BEFORE -> $SIZE_AFTER"