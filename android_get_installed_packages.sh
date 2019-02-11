#!/bin/bash

########################################

showHelp() {
cat << EOF
Usage: $(basename $0) [--grep=PATTERN] [--color] [--help]
Show installed packages and versions by adb

  --grep   	Use pattern with grep
  --color	Colored output
  --help        Show this help and exit
EOF
}

########################################

GREP_PATTERN=
COLOR=0

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
	    --color)
	    	COLOR=1
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
BL='\033[1;34m'
NC='\033[0m'

for P in "${PACKAGES[@]}"; do
	NAME=$(echo "${P//[$'\t\r\n ']}")
	VERSIONS=($(adb shell dumpsys package $NAME | grep -i versionName | awk -F"=" '{print $2}'))
	if [ $COLOR == 1 ]; then
		echo -e "$NAME ${BL}$VERSIONS${NC}"
	else
		echo "$NAME $VERSIONS"
	fi
done