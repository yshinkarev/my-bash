#!/bin/bash

SITE=$1
if [ -z "$SITE" ]; then
	echo "Missing argument: WEB SITE"
	exit 1
fi

echo | openssl s_client -showcerts -servername $SITE -connect $SITE:443 2>/dev/null | openssl x509 -inform pem -noout -text