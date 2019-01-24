#!/bin/bash

AUTH_FILE=${0%.*}; AUTH_FILE=$AUTH_FILE.conf

if [ -f $AUTH_FILE ]; then
	mapfile -t AUTH < $AUTH_FILE
fi

if [ -z "$CHAT_ID" ]; then
	CHAT_ID=${AUTH[0]}
fi

if [ -z "$BOT_TOKEN" ]; then
	BOT_TOKEN=${AUTH[1]}
fi

if [ -z "$CHAT_ID" ] || [ -z "$BOT_TOKEN" ]; then
	>&2 echo "No CHAT_ID or BOT_TOKEN"
	exit 1
fi

########################################

waitConnectionIfNeeded() {
	if [ -z "$WAIT_CONNECT_SECONDS" ]; then
		return
	fi

	START=$(date +%s)
	echo $TO_END
	while true
	do
		wget -q --spider https://google.com

		if [ $? -eq 0 ]; then
			return
		fi

		sleep 1
		END=$(date +%s)
		DIFF=$(( $END - $START ))
		if [ $DIFF -ge $WAIT_CONNECT_SECONDS ]; then
			>&2 echo "Waiting connection timeout"
			exit 1
		fi
	done
}

urlencode() {
  local length="${#1}"
  for (( i = 0; i < length; i++ )); do
    local c="${1:i:1}"
    case $c in
      [a-zA-Z0-9.~_-]) printf "$c" ;;
    *) printf "$c" | xxd -p -c1 | while read x;do printf "%%%s" "$x";done
  esac
done
}

########################################
LOG_FILE=
SEND_FILE=
TEXT=
WAIT_CONNECT_SECONDS=
FROM=

for arg in "$@"; do
	case $arg in
	    --log-file=*)
	  	LOG_FILE=${arg#*=}
	  	shift
	  	;;
	    --from=*)
	  	FROM=${arg#*=}
	  	shift
	  	;;
	    --send-file=*)
	  	SEND_FILE=${arg#*=}
	  	shift
	  	;;
	    --message=*)
	  	TEXT=${arg#*=}
	  	shift
	  	;;
	    --wait-connect=*)
	  	WAIT_CONNECT_SECONDS=${arg#*=}
	  	if ! [[ $WAIT_CONNECT_SECONDS =~ ^[0-9]+$ ]] || [ $WAIT_CONNECT_SECONDS -lt 1 ]; then
	  		>&2 echo "wait-connect argument should be a number (seconds > 0)"
			exit 1
	  	fi
	  	shift
	  	;;
	  esac
	done
########################################


if [ -n "$LOG_FILE" ]; then
	exec > >(tee -ia $LOG_FILE)
	exec 2>&1
fi

FORCED_MESSAGE=1; [ -z "$TEXT" ] && FORCED_MESSAGE=0

if [ -z "$TEXT" ]; then
	# TEXT="${@: -1}"	
	for TEXT; do true; done	
fi

if [ -z "$FROM" ]; then
	FROM="[$(whoami)@$(hostname)]"
fi

if [ -z "$SEND_FILE" ]; then
	if [ -z "$TEXT" ]; then
		>&2 echo "Missing MESSAGE"
		exit 1
	fi
	if [ $FORCED_MESSAGE == 0 ]; then
		set -- "${@:1:$(($#-1))}"
	fi
	
	waitConnectionIfNeeded	
	wget --post-data "text=$FROM $TEXT" --output-document=/dev/null "https://api.telegram.org/$BOT_TOKEN/sendmessage?chat_id=$CHAT_ID" $@	
	exit 0
fi

if [ ! -f $SEND_FILE ]; then
	>&2 echo "No such file $SEND_FILE"
	exit 1
fi

DIR_PATH=$(dirname "$SEND_FILE")
if [ -n "$TEXT" ]; then
	TEXT="$TEXT "
fi
if [ $FORCED_MESSAGE == 0 ]; then
	set -- "${@:1:$(($#-1))}"
fi

TEXT="$TEXT(path: $DIR_PATH)"

waitConnectionIfNeeded
curl "https://api.telegram.org/$BOT_TOKEN/senddocument" -F "chat_id=$CHAT_ID" -F "document=@$SEND_FILE" -F "caption=$FROM $TEXT" $@
echo