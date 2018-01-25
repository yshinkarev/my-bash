#!/bin/bash
# https://askubuntu.com/questions/51854/is-it-possible-to-install-a-deb-from-a-url

URL=$1

if [ -z "$URL" ]; then
	>&2 echo "Missing argument URL"
fi

TEMP_DEB="$(mktemp).deb"
echo "Download deb to file $TEMP_DEB..."
wget "$URL" -O "$TEMP_DEB" 2> /dev/null
echo "Install deb..."
sudo dpkg -i "$TEMP_DEB"

if [[ "$@" == *"--delete"* ]]; then
	echo "Delete $TEMP_DEB"
	rm -f "$TEMP_DEB"
fi

