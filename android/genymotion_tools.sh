#!/usr/bin/env bash

FILE_NAME=$(basename "$0"); ONLY_NAME=${FILE_NAME%.*}; LOG_FILE=/tmp/${ONLY_NAME}.log

########################################
K_LIST="--list"
K_FIND="--find"
K_START="--start"
K_STOP="--stop"
K_ASPECT="--aspect"
K_STOP_ALL="--stop-all"
K_START_ALL="--start-all"
K_KWORDS="--keywords"
K_CMPL_INS="--complete-install"
K_CMPL_UNINS="--complete-uninstall"
K_HLP="--help"
ALL_KEYWORDS=("${K_LIST}" "${K_FIND}=" "${K_START}"= "${K_STOP}"= "${K_STOP_ALL}" "${K_START_ALL}" "${K_ASPECT}=" "${K_KWORDS}" "${K_CMPL_INS}" "${K_CMPL_UNINS}" "${K_HLP}")
########################################
showHelp() {
	cat << EOF
Usage: $(basename $0) <command>
Simple wrapper for genymotion.

  ${K_LIST}                 Lists available virtual devices
  ${K_FIND}=NAME            Find virtual device by pattern NAME
  ${K_START}=NAME           Start virtual device by pattern name NAME
  ${K_STOP}=NAME            Stop virtual device by pattern name NAME
  ${K_STOP_ALL}             Stop all running virtual devices
  ${K_START_ALL}            Start all available virtual devices
  ${K_ASPECT}=VALUE         Increase window size in VALUE times for started virtual devices
                         VALUE=0.5 - reduce window size in 2 times.
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
    if [[ -z ${NAME} ]]; then
        >&2 echo "Missing argument: pattern name"
        exit 1
    fi
    FATAL_ON_ERROR=$2
    local -n _VM_NAMES=$3
    mapfile -t _VM_NAMES < <( genyshell -c "devices list" 2>&1 | sed -n -e '/ Id /,$p' | sed 's/.*| //' | grep -i "${NAME}" )
    if [[ ${FATAL_ON_ERROR} -eq 1 ]] && [[ -z ${_VM_NAMES} ]] ; then
        >&2 echo "Virtual device with pattern name '$NAME' not found"
        exit 1
    fi
}
########################################
change_aspect() {
    ASPECT=$1
    mapfile -t VMS < <( wmctrl -l | grep " - Genymotion" )
    if [[ ${#VMS[@]} -eq 0 ]]; then
	    echo "No started virtual devices"
	else
	    for WM in "${VMS[@]}"; do
            HEX_WID=$(echo "${WM}" | cut -d' ' -f 1)
            WID=$(printf '%d\n' ${HEX_WID})
            unset X Y WIDTH HEIGHT
            eval $(xwininfo -id ${WID} | sed -e "s/^ \+Absolute upper-left X: \+\([0-9]\+\).*/X=\1/p" \
           -e "s/^ \+Absolute upper-left Y: \+\([0-9]\+\).*/Y=\1/p" \
            -n -e "s/^ \+Width: \+\([0-9]\+\).*/WIDTH=\1/p" \
            -e "s/^ \+Height: \+\([0-9]\+\).*/HEIGHT=\1/p" )
            NEW_WIDTH=$(bc -l <<< "scale=0; ${WIDTH}*${ASPECT}")
            NEW_WIDTH=${NEW_WIDTH%.*}
            NEW_HEIGHT=$(bc -l <<< "scale=0; ${HEIGHT}*${ASPECT}")
            NEW_HEIGHT=${NEW_HEIGHT%.*}
            echo "Window ${WID} (${X},${Y}) ${WIDTH}x${HEIGHT} => ${NEW_WIDTH}x${NEW_HEIGHT}"
            wmctrl -i -r ${WID} -e 0,${X},${Y},${NEW_WIDTH},${NEW_HEIGHT}
	    done
	fi
}
########################################
start_vm_by_names() {
    _VM_NAMES=("$@")
    for VM_NAME in "${_VM_NAMES[@]}"; do
        echo "Start \"${VM_NAME}\""
  		nohup player --vm-name "${VM_NAME}" </dev/null >/dev/null 2>&1 &
	done
}
########################################
start_vm() {
    local VM_NAMES=()
    find_vm $1 1 VM_NAMES
    start_vm_by_names "${VM_NAMES[@]}"
}
########################################
stop_vm_by_names() {
    _VM_NAMES=("$@")
    for VM_NAME in "${_VM_NAMES[@]}"; do
        echo "Stop \"${_VM_NAMES}\""
        player -n "${VM_NAME}" -x 2> /dev/null
	done
}
########################################
stop_vm() {
    local VM_NAMES=()
    find_vm $1 1 VM_NAMES
    stop_vm_by_names "${VM_NAMES[@]}"
}
########################################
stop_all() {
    mapfile -t _VM_NAMES < <( genyshell -c "devices list" 2>&1 | sed -n -e '/ Id /,$p' | grep -i " on " | sed 's/.*| //' )
    if [[ ${#_VM_NAMES[@]} -eq 0 ]]; then
	    echo "No started virtual devices"
	else
	    stop_vm_by_names "${_VM_NAMES[@]}"
	fi
}
########################################
start_all() {
    mapfile -t _VM_NAMES < <( genyshell -c "devices list" 2>&1 | sed -n -e '/ Id /,$p' | grep -i " off " | sed 's/.*| //' )
    if [[ ${#_VM_NAMES[@]} -eq 0 ]]; then
	    echo "No available virtual devices"
	else
	    start_vm_by_names "${_VM_NAMES[@]}"
	fi
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
  if [[ $(whoami) == "schumi" ]]; then
	    echo "complete -o nospace -F _genymotion gm" >> ${TMP_FILE}
	fi
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
if [[ "$@" == *"${K_HLP}"* ]] || [[ "$#" -eq 0 ]] ; then
	showHelp
	exit 0
fi

for arg in "$@"; do
	case ${arg} in
	    ${K_LIST})
	  	    devices_list
	  	    exit 0
	  	    ;;
	  	${K_ASPECT}=*)
	  	    ASPECT=${arg#*=}
	  	    if ! [[ ${ASPECT} =~ ^[+-]?[0-9]+([.][0-9]+)?$ ]] ; then
		        >&2 echo "Expected number/float"
		        exit 1
	        fi
	        change_aspect ${ASPECT}
	  	    ;;
	  	${K_FIND}=*)
	  	    VM_NAMES=()
	  	    find_vm ${arg#*=} 1 VM_NAMES
	  	    printf '%s\n' "${VM_NAMES[@]}"
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
	  	${K_STOP_ALL})
	  	    stop_all
	  	    exit 0
	  	    ;;
	  	${K_START_ALL})
	  	    start_all
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
