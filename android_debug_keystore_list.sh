#!/bin/bash

FILE=~/.android/debug.keystore
#######################################
for arg in "$@"; do
	case $arg in
	    --file=*)
	  	FILE=${arg#*=}
	  	shift
	  	;;
	  esac
	done
#######################################

if [ ! -f $FILE ]; then
	    >&2 echo "File not found"
fi

keytool -list -v -keystore $FILE -alias androiddebugkey -storepass android -keypass android