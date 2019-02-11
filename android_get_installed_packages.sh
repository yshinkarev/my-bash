#!/bin/bash

########################################

showHelp() {
cat << EOF
Usage: $(basename $0) [--grep=PATTERN][--help]
Show installed packages and versions by adb

  --grep   	Use pattern with grep
  --help        Show this help and exit
EOF
}

########################################

GREP_PATTERN=

if [[ "$@" == *"--help"* ]]; then
	showHelp
	exit 0
fi

for arg in "$@"; do
	  case $arg in
	    --grep=*)
	    	GREP_PATTERN=${arg#*=}
	    	shift 1
	    	;;
	    *)
	      >&2 echo "Unknown argument: $arg"
	      exit 1
	      ;;
	  esac
	done

########################################

if [ -z "$GREP_PATTERN" ]; then
	PACKAGES=($(adb shell "pm list packages -f" | cut -f 2 -d "="))
else
	PACKAGES=($(adb shell "pm list packages -f" | grep -iE "$GREP_PATTERN" | cut -f 2 -d "="))
fi

if [ ${#PACKAGES[@]} == 0 ]; then
	echo "No packages found"
	exit 0
fi

echo "Found packages: ${#PACKAGES[@]}"

for P in "${PACKAGES[@]}"; do
	NAME=$(echo "${P//[$'\t\r\n ']}")
	VERSIONS=($(adb shell dumpsys package $NAME | grep -i versionName | awk -F"=" '{print $2}'))
	echo "$NAME $VERSIONS"
done