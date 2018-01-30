#!/bin/bash

humanFormat() {
	echo $(numfmt --to=iec-i --suffix=B --format="%.1f" $1)
}

FILE=~/.bash_history
SIZE_BEFORE=$(humanFormat $(stat -c%s "$FILE"))

TMP_FILE=$(mktemp history.XXX)
awk '!seen[$0]++' $FILE > $TMP_FILE

mv $FILE $FILE.bak
mv $TMP_FILE $FILE
rm -f $TMP_FILE

SIZE_AFTER=$(humanFormat $(stat -c%s "$FILE"))
echo "$FILE processed: $SIZE_BEFORE -> $SIZE_AFTER"