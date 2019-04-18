#!/usr/bin/env bash

INIT_DIR=$(pwd)
DIRECTORY=.
CMD=
FILE_NAME=$(basename "$0"); ONLY_NAME=${FILE_NAME%.*}; LOG_FILE=/tmp/${ONLY_NAME}.log

set -e
function cleanup {
	cd ${INIT_DIR} > /dev/null
}
trap cleanup EXIT

########################################
K_GET_OS_VER="--get-os-versions"
K_DEVICES="--devices"
K_KWORDS="--keywords"
K_HLP="--help"
K_CMPL_INS="--complete-install"
K_CMPL_UNINS="--complete-uninstall"
ALL_KEYWORDS=("${K_GET_OS_VER}" "${K_DEVICES}" "${K_KWORDS}" "${K_CMPL_INS}" "${K_CMPL_UNINS}" "${K_HLP}")
########################################
showHelp() {
	cat << EOF
Usage: $(basename $0) <command>
Simple wrapper for android.

  ${K_GET_OS_VER}      Show android OS versions of connected devices
  ${K_DEVICES}              Show connected devices
  ${K_KWORDS}             Show available arguments
  ${K_CMPL_INS}     Configure auto completion for script
  ${K_CMPL_UNINS}   Remove auto completion for scrip
  ${K_HLP}                 Show this help and exit
EOF
}
########################################
get_connected_devices() {
    adb devices | grep -v devices | grep device | cut -f 1
}
########################################
get_os_versions() {
    DEVICES=$(get_connected_devices)
    OUT=()
    for DEV in ${DEVICES[@]}; do
        VER=$(adb -s ${DEV} shell getprop ro.build.version.release)
        echo "${DEV} ${VER}"
	done | column -t
}
########################################
show_connected_devices() {
    DEVICES=$(get_connected_devices)
    for DEV in ${DEVICES[@]}; do
        echo ${DEV}
	done
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
	echo '_android_tools()
{
  opts=$('$(realpath $0)' --keywords)
  local cur prev
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
  return 0
}
complete -o nospace -F _android_tools '${FILE_NAME}'' > ${TMP_FILE}
	sudo mv $TMP_FILE ${FILE}
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

for arg in "$@"; do
	case ${arg} in
	    ${K_GET_OS_VER})
	  	 get_os_versions
	  	 exit 0
	  	 ;;
	    ${K_DEVICES})
	  	 show_connected_devices
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
	         >&2 echo "Unknown argument: $arg"
	         exit 1
	         ;;
	  esac
	done