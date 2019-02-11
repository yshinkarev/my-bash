#!/bin/bash

########################################

showHelp() {
cat << EOF
Usage: $(basename $0) [--mask=FILES_MASK] [--color] [--help]
Show information about apk files filtered by name

  --mask   	Filter filename mask
  --color	Colored output
  --help        Show this help and exit
EOF
}

########################################

FILES_MASK=*.apk
COLOR=0

if [[ "$@" == *"--help"* ]]; then
	showHelp
	exit 0
fi

for arg in "$@"; do
	  case $arg in
	    --mask=*)
	    	FILES_MASK=${arg#*=}
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

BL='\033[1;34m'
GR='\033[0;32m'
NC='\033[0m'

for APK in $FILES_MASK; do
	PACKAGE_INFO=`aapt dump badging $APK | grep -E "package|launchable-activity|versionCode"`
	PACKAGE=`echo $PACKAGE_INFO | sed "s/.*package: name='\([^']*\)'.*/\1/"`
	VERSION=`echo $PACKAGE_INFO | sed "s/.* versionCode='\([^']*\)'.*/\1/"`

	ACTIVITY=`echo $PACKAGE_INFO | sed -e "s/.*launchable-activity: name='\([^']*\)'.*/\1/g"`
	if [[ $ACTIVITY == *"package: name"* ]]; then
		ACTIVITY=
	fi
	if [ $COLOR == 1 ]; then
		echo -e "$APK ${BL}$PACKAGE${NC} $VERSION ${GR}$ACTIVITY${NC}"
	else
		echo "$APK $PACKAGE $VERSION $ACTIVITY"
	fi
done