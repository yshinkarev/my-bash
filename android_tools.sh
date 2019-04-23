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
K_GET_DB="--get-db"
K_GET_FILE="--get-file"
ALL_KEYWORDS=("${K_GET_OS_VER}" "${K_DEVICES}" "${K_KWORDS}" "${K_CMPL_INS}" "${K_CMPL_UNINS}" "${K_GET_DB}=" "${K_GET_FILE}=" "${K_HLP}")
########################################
showHelp() {
	cat << EOF
Usage: $(basename $0) <command>
Simple wrapper for android.

  ${K_GET_OS_VER}      Show android OS versions of connected devices
  ${K_DEVICES}              Show connected devices
  ${K_GET_DB}=FILE          Download sqlite3 database with name FILE from internal storage (uses stetho, dumpsys)
  ${K_GET_FILE}=FILE        Download file from internal storage (uses stetho, dumpsys)
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
check_dumpapp_avail() {
   which dumpapp.sh >/dev/null
    if [[ $? -ne 0 ]]; then
        >&2 echo "dumpapp.sh not found."
        >&2 echo "Please read https://facebook.github.io/stetho"
        >&2 echo  "Seems https://github.com/facebook/stetho/blob/master/scripts/dumpapp that's your need, rename file to dumpapp.sh."
        exit 1
    fi
}
########################################
humanFormat() {
	echo $(numfmt --to=iec-i --suffix=B --format="%.1f" $1)
}
########################################
download_file() {
    FILE=$1
    ONLY_NAME=$(basename "$FILE")
    dumpapp.sh files download - ${FILE} | zcat > ${ONLY_NAME}
	SIZE=$(humanFormat $(stat -c%s "${ONLY_NAME}"))
    echo "${ONLY_NAME} ${SIZE}"
}
########################################
get_db() {
    NAME=$1
    if [[ -z ${NAME} ]]; then
        >&2 echo "Missing argument: file name"
        exit 1
    fi
    check_dumpapp_avail
    download_file "databases/${NAME}"
    download_file "databases/${NAME}-shm"
    download_file "databases/${NAME}-wal"
    which sqlite3 >/dev/null
    if [[ $? -eq 0 ]]; then
        sqlite3 ${NAME} VACUUM;
        RC=$?;
	    if [[ ${RC} != 0 ]]; then
		    exit ${RC};
	    fi
	    FINAL_NAME="${NAME}.sqlite3"
	    mv ${NAME} ${FINAL_NAME}
	    RC=$?;
	    if [[ ${RC} != 0 ]] || [[ ! -f ${FINAL_NAME} ]]; then
		    exit ${RC};
	    fi
	    SIZE=$(humanFormat $(stat -c%s "${FINAL_NAME}"))
	    echo "Final file: ${FINAL_NAME} ${SIZE}"
    fi
}
########################################
get_file() {
    NAME=$1
    if [[ -z ${NAME} ]]; then
        >&2 echo "Missing argument: file name"
        exit 1
    fi
    check_dumpapp_avail
    download_file ${NAME}
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
	  	${K_GET_DB}=*)
	  	    get_db ${arg#*=}
	  	    exit 0
	  	    ;;
	  	${K_GET_FILE}=*)
	  	    get_file ${arg#*=}
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