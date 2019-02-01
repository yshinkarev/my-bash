#!/bin/bash

function cleanup {
if [ -n "$SSH_KEY_FILE" ]; then
	ssh-add -D
fi

# if run by sudo, then change own of file to default user.
if [[ $EUID -eq 0 ]]; then
	USER_TO=$(whoami | awk '{print $1}')
	GROUP_TO=$(groups $USER_TO | awk '{print $3}')
	chown $USER_TO:$GROUP_TO $LOG_FILE
fi

}
trap cleanup EXIT

FILENAME=$(basename "$0"); ONLYNAME=${FILENAME%.*}; LOG_FILE=/tmp/$ONLYNAME.log
SSH_KEY_FILE=
NO_SSH_KEY=0
DIRECTORY=./

########################################

for arg in "$@"; do
	  case $arg in
	    --sshkeyfile==*)
	  	SSH_KEY_FILE=${arg#*=}
	  	;;
	    --directory=*)
	  	DIRECTORY=${arg#*=}
	  	;;
	    --logfile=*)
	  	LOG_FILE=${arg#*=}
	  	;;
	    --no-ssh-key)
	  	NO_SSH_KEY=1
	  	;;
	    *)
	      echo "Unknown argument: $arg"
	      help
	      exit 1
	      ;;
	  esac
	done

########################################

if [ $NO_SSH_KEY == 0 ]; then
	SSH_KEY_FILE=
fi

echo "   Log file: [$LOG_FILE]"
echo "   Directory: [$DIRECTORY]"
if [ -n "$SSH_KEY_FILE" ]; then
	echo "   SshKeyFile: [$SSH_KEY_FILE]"
fi

rm -f $LOG_FILE
exec > >(tee -ia $LOG_FILE)
exec 2>&1

if [ -n "$SSH_KEY_FILE" ]; then
	ssh-add $SSH_KEY_FILE
fi

for DIR in $(find $DIRECTORY -type d -iname .git 2>/dev/null); do
	TARGET="${DIR%.git}"
	echo "*************** Pulling $TARGET ***************"
	cd $TARGET
	git pull --rebase
	cd - > /dev/null
done