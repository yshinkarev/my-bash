#!/bin/bash

FILE_NAME=$(basename "$0"); ONLY_NAME=${FILE_NAME%.*}; LOG_FILE=/tmp/${ONLY_NAME}.log

########################################
K_LIST="--list"
K_FIND="--find"
K_START="--start"
K_STOP="--stop"
K_KWORDS="--keywords"
K_CMPL_INS="--complete-install"
K_CMPL_UNINS="--complete-uninstall"
K_HLP="--help"
ALL_KEYWORDS=("${K_LIST}" "${K_FIND}=" "${K_START}"= "${K_STOP}"= "${K_KWORDS}" "${K_CMPL_INS}" "${K_CMPL_UNINS}" "${K_HLP}")
########################################
showHelp() {
	cat << EOF
Usage: $(basename $0) <command>
Simple wrapper for genymotion.

  ${K_LIST}                 Lists available virtual devices
  ${K_FIND}=NAME            Find virtual device by pattern NAME
  ${K_START}=NAME           Start virtual device by pattern name NAME
  ${K_STOP}=NAME            Stop virtual device by pattern name NAME
  ${K_KWORDS}             Print available arguments
  ${K_CMPL_INS}     Configure auto completion for script
  ${K_CMPL_UNINS}   Remove auto completion for script
  ${K_HLP}                 Print this help and exit
EOF
}
########################################
devices_list() {
	genyshell -c "devices list" 2>&1 | sed -n -e '/ Id /,$p'
}
########################################
find_vm() {
    NAME=$1
    FATAL_ON_ERROR=$2
    if [[ -z ${NAME} ]]; then
        >&2 echo "Missing argument: pattern name"
    fi
    VM=$(devices_list | grep -i ${NAME})
    if [[ -n ${VM} ]]; then
        VM_NAME=$(echo ${VM} | sed 's/.*| //')
    fi
    if [[ ${FATAL_ON_ERROR} -eq 1 ]] && [[ -z ${VM_NAME} ]] ; then
        >&2 echo "Virtual device with pattern name '$NAME' not found"
        exit 1
    fi
    echo ${VM_NAME}
}
########################################
start_vm() {
    VM_NAME=$(find_vm $1 1)
    echo "Start ${VM_NAME}"
	nohup player --vm-name "${VM_NAME}" </dev/null >/dev/null 2>&1 &
}
########################################
stop_vm() {
    VM_NAME=$(find_vm $1 1)
    echo "Stop ${VM_NAME}"
    player -n "${VM_NAME}" -x
}
########################################
show_keywords() {
	KEYWORDS=$(printf " %s" "${ALL_KEYWORDS[@]}")
	echo "${KEYWORDS:1}"
}
########################################
get_complete_file() {
	echo "/etc/bash_completion.d/${ONLY_NAME}"
}
########################################
complete_install() {
	FILE=$(get_complete_file)
	TMP_FILE=$(mktemp /tmp/${ONLY_NAME}.XXXXXX)
	echo '_genymotion()
{
  opts=$('$(realpath $0)' --keywords)
  local cur prev
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
  return 0
}
complete -o nospace -F _genymotion '${FILE_NAME}'' > ${TMP_FILE}
	sudo mv ${TMP_FILE} ${FILE}
	sudo chown root:root ${FILE}
	sudo chmod 644 ${FILE}
}
########################################
complete_uninstall() {
	FILE=$(get_complete_file)
	sudo rm ${FILE}
}
######################################## MAIN ########################################
if [[ "$@" == *"${K_HLP}"* ]]; then
	showHelp
	exit 0
fi

# devices_list
# run_vm

# nohup genymotion > /dev/null 2>&1 &

for arg in "$@"; do
	case ${arg} in
	    ${K_LIST})
	  	    devices_list
	  	    exit 0
	  	    ;;
	  	${K_FIND}=*)
	  	    find_vm ${arg#*=} 1
	  	    exit 0
	  	    ;;
	  	${K_START}=*)
	  	    start_vm ${arg#*=}
	  	    exit 0
	  	    ;;
	  	${K_STOP}=*)
	  	    stop_vm ${arg#*=}
	  	    exit 0
	  	    ;;
	    ${K_KWORDS})
	    	show_keywords
	    	exit 0
	    	;;
	    ${K_CMPL_INS})
	    	 complete_install
	    	 exit 0
	    	 ;;
	    ${K_CMPL_UNINS})
	    	 complete_uninstall
	    	 exit 0
	    	 ;;
	    *)
	         >&2 echo "Unknown argument: ${arg}"
	         exit 1
	         ;;
	  esac
	done