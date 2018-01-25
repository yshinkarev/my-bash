#!/bin/bash

INIT_DIR=$(pwd)
START=$(date +%s)

logStage() {
	END=$(date +%s)
	DIFF=$(( $END - $START ))
	printf "[%05ds] " $DIFF
	echo $@
}

########################################
USER_TO_TAR=$USER
EXCLUDE_FROM=${0%.*}.txt
TARGET_DIR=
TARGET_FILE_NAME=
COMPRESS=

for arg in "$@"; do
	case $arg in
	    --user=*)
	  	USER_TO_TAR=${arg#*=}
	  	shift
	  	;;
	    --exclude-from=*)
	  	EXCLUDE_FROM=${arg#*=}
	  	shift
	  	;;
	    --target-dir=*)
	  	TARGET_DIR=${arg#*=}
	  	shift
	  	;;
	    --target-filename=*)
	  	TARGET_FILE_NAME=${arg#*=}
	  	shift
	  	;;
	    --compress=*)
	  	COMPRESS=${arg#*=}
	  	shift
	  	;;
	    *)
	      echo "Unknown argument: $arg"
	      exit 1
	      ;;
	  esac
	done
########################################

id "$USER_TO_TAR" > /dev/null 2>&1
rc=$?;
if [[ $rc != 0 ]]; then
	>&2 echo "User $USER_TO_TAR does not exists"
	exit 1
fi

if [ ! -f $EXCLUDE_FROM ]; then
	>&2 echo "Exclude file $EXCLUDE_FROM does not exists"
	exit 1
fi

HOME_PATH=$(eval echo "~$USER_TO_TAR")
if [ ! -d $HOME_PATH ]; then
	>&2 echo "Home directory $HOME_PATH does not exists"
	exit 1
fi

if [ -z $TARGET_DIR ]; then
	TARGET_DIR=$HOME_PATH
fi

if [ -z $TARGET_FILE_NAME ]; then
	TARGET_FILE_NAME=$USER_TO_TAR@$(hostname)-$(date +"%Y.%m.%d-%H_%M_%S").tar
	case $COMPRESS in
		*lbzip2)
		TARGET_FILE_NAME=$TARGET_FILE_NAME.bz
		;;
		*bpzip2)
		TARGET_FILE_NAME=$TARGET_FILE_NAME.bz
		;;
		*pigz)
		TARGET_FILE_NAME=$TARGET_FILE_NAME.gz
		;;
	esac
fi

if [ ! -d $TARGET_DIR ]; then
	>&2 echo "Target directory $TARGET_DIR does not exists"
	exit 1
fi

DEST_PATH=$TARGET_DIR/$TARGET_FILE_NAME
########################################
logStage "Compressing to $DEST_PATH"
# Needed, because used cd, but target dir can be set as relative path.
DEST_PATH=$(readlink -f $DEST_PATH)
cd $HOME_PATH

if [ -z $COMPRESS ]; then
	tar -cf $DEST_PATH . --exclude-from=$EXCLUDE_FROM
else
	tar -I $COMPRESS -cf $DEST_PATH . --exclude-from=$EXCLUDE_FROM
fi

cd - > /dev/null
logStage "Testing"
if ! tar tf $DEST_PATH &> /dev/null; then
    >&2 echo "Compressed archive does not verified (not found)"
    exit 1
fi

logStage "Calculating MD5"
cd $TARGET_DIR
md5sum $TARGET_FILE_NAME > $TARGET_FILE_NAME.md5

END=$(date +%s)
DIFF=$(( $END - $START ))
logStage "Finished"
cd $INIT_DIR > /dev/null