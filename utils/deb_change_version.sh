#!/usr/bin/env bash

DEBFILE=$1
if [[ -z "$DEBFILE" ]]; then
	>&2 echo "Missing argument deb-file"
	exit 1
fi

NEW_VERSION=$2
if [[ -z "$NEW_VERSION" ]]; then
	>&2 echo "Missing argument new version"
	exit 1
fi

set -e
function cleanup {
	rm -rf "$TMPDIR"
}
trap cleanup EXIT

TMPDIR=`mktemp -d /tmp/deb.XXXXXXXXXX` || exit 1
OUTPUT=$DEBFILE.modified

if [[ -e "$OUTPUT" ]]; then
	>&2 echo "$OUTPUT exists"
	exit 1
fi

dpkg-deb -x "$DEBFILE" "$TMPDIR"
dpkg-deb --control "$DEBFILE" "$TMPDIR"/DEBIAN

if [[ ! -e "$TMPDIR"/DEBIAN/control ]]; then
	>&2 echo "DEBIAN/control not found"
	exit 1
fi

CONTROL="$TMPDIR"/DEBIAN/control
sed -i "s/Version:.*/Version: $NEW_VERSION/g" $CONTROL

dpkg -b "$TMPDIR" "$OUTPUT"
echo "New file $OUTPUT generated"