#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if (( $# == 0 )); then
  echo "Text is required." >&2
  exit 1
fi

text="$*"
text="${text// /%s}"
text="${text//\\/\\\\}"
text="${text//!/\\!}"
text="${text//\(/\\(}"
text="${text//\)/\\)}"
text="${text//\&/\\&}"
text="${text//\|/\\|}"
text="${text//\;/\\;}"
text="${text//\</\\<}"
text="${text//\>/\\>}"
text="${text//\*/\\*}"
text="${text//#/\\#}"

"$SCRIPT_DIR/adb_all.sh" shell input text "$text"
