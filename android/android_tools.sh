#!/usr/bin/env bash

INIT_DIR=$(pwd)
FILE_NAME=$(basename "$0")
ONLY_NAME=${FILE_NAME%.*} #LOG_FILE=/tmp/${ONLY_NAME}.log

function cleanup() {
    cd "${INIT_DIR}" >/dev/null
}
trap cleanup EXIT

########################################
K_GET_OS_VER="--get-os-versions"
K_DEVICES="--devices"
K_KWORDS="--keywords"
K_CMPL_INS="--complete-install"
K_CMPL_UNINS="--complete-uninstall"
K_GET_DB="--get-db"
K_GET_FILE="--get-file"
K_GET_PKG_DATA="--get-data"
K_DATA_BACKUP="--data-backup"
K_DATA_RESTORE="--data-restore"
K_PREFS="--files-prefs"
K_UNINSTALL="--uninstall"
K_PULL_APK="--pull-apk"
K_SEND_ACTION="--send-action"
ACTION_BOOT="boot"
ACTION_BOOT_V="ACTION_BOOT_COMPLETED"
K_FOCUSED_WND="--focused-wnd"
K_WIFI="--wifi"
K_DEV_PROPS="--dev-props"
K_GET_CERT_PIN="--get-cert-pin"
K_SYNC_TIME_WITH_HOST="--sync-time-with-host"
K_HLP="--help"
ALL_KEYWORDS=("${K_GET_OS_VER}" "${K_DEVICES}" "${K_KWORDS}" "${K_CMPL_INS}" "${K_CMPL_UNINS}" "${K_GET_DB}=" "${K_GET_FILE}=" "${K_GET_PKG_DATA}=" "${K_DATA_BACKUP}=" "${K_DATA_RESTORE}=" "${K_PREFS}=" "${K_UNINSTALL}=" "${K_PULL_APK}=" "${K_SEND_ACTION}=" "${K_FOCUSED_WND}" "${K_WIFI}=" "${K_DEV_PROPS}" "${K_GET_CERT_PIN}" "${K_SYNC_TIME_WITH_HOST}" "${K_HLP}")
########################################
showHelp() {
    cat <<EOF
Usage: $(basename "$0") <command>
Simple wrapper for android.

  ${K_GET_OS_VER}           Print android OS versions of connected devices
  ${K_DEVICES}                   Print connected devices
  ${K_GET_DB}=FILE               Download sqlite3 database with name FILE from internal storage (uses stetho, dumpsys)
  ${K_GET_FILE}=FILE             Download file from internal storage (uses stetho, dumpsys)
  ${K_GET_PKG_DATA}=PACKAGE_NAME     Download application directory from internal storage (needed su)
  ${K_DATA_BACKUP}=PACKAGE_NAME  Backup application user data (needed root)
  ${K_DATA_RESTORE}=PACKAGE_NAME Restore application user data (needed root)
  ${K_PREFS}=PACKAGE_NAME  Print content of preferences (needed root)
  ${K_UNINSTALL}=TARGET          Uninstall application by TARGET, where TARGET is package name or local apk-file
  ${K_PULL_APK}=PACKAGE_NAME     Download apk from device by package name
  ${K_SEND_ACTION}=ACTION        Send broadcast action ACTION (standart or own).
                              Standart values: ${ACTION_BOOT} (${ACTION_BOOT_V})
  ${K_FOCUSED_WND}               Print focused window
  ${K_WIFI}=FLAG                 Enable/disable wifi, FLAG=on|off
  ${K_DEV_PROPS}                 Print device properties
  ${K_GET_CERT_PIN}              Get certificate pin (sha256) for server
  ${K_SYNC_TIME_WITH_HOST}       Sync android device time with host time
  ${K_KWORDS}                  Print available arguments
  ${K_CMPL_INS}          Configure auto completion for script
  ${K_CMPL_UNINS}        Remove auto completion for script
  ${K_HLP}                      Print this help and exit
EOF
}
########################################
get_connected_devices() {
    adb devices | grep -v devices | grep device | cut -f 1
}
########################################
get_os_versions() {
    DEVICES=$(get_connected_devices)
    for DEV in ${DEVICES}; do
        VER=$(adb -s "${DEV}" shell getprop ro.build.version.release)
        echo "${DEV} ${VER}"
    done | column -t
}
########################################
show_connected_devices() {
    DEVICES=$(get_connected_devices)
    for DEV in ${DEVICES}; do
        echo "${DEV}"
    done
}
########################################
check_dumpapp_avail() {
    which dumpapp >/dev/null
    if [[ $? -ne 0 ]]; then
        echo >&2 "dumpapp not found."
        echo >&2 "Please read https://facebook.github.io/stetho"
        echo >&2 "Seems https://github.com/facebook/stetho/blob/master/scripts/dumpapp that's your need, rename file to dumpapp."
        exit 1
    fi
}
########################################
humanFormat() {
    numfmt --to=iec-i --suffix=B --format="%.1f" "$1"
}
########################################
download_file() {
    FILE=$1
    ONLY_NAME=$(basename "$FILE")
    dumpapp files download - "${FILE}" | zcat >"${ONLY_NAME}"
    SIZE=$(humanFormat $(stat -c%s "${ONLY_NAME}"))
    echo "${ONLY_NAME} ${SIZE}"
}
########################################
get_db() {
    NAME=$1
    if [[ -z ${NAME} ]]; then
        echo >&2 "Missing argument: file name"
        exit 1
    fi
    check_dumpapp_avail
    download_file "databases/${NAME}"
    download_file "databases/${NAME}-shm"
    download_file "databases/${NAME}-wal"
    which sqlite3 >/dev/null
    if [[ $? -eq 0 ]]; then
        sqlite3 "${NAME}" VACUUM
        RC=$?
        if [[ ${RC} != 0 ]]; then
            exit ${RC}
        fi
        FINAL_NAME="${NAME}.sqlite3"
        mv "${NAME}" "${FINAL_NAME}"
        RC=$?
        if [[ ${RC} != 0 ]] || [[ ! -f ${FINAL_NAME} ]]; then
            exit ${RC}
        fi
        SIZE=$(humanFormat $(stat -c%s "${FINAL_NAME}"))
        echo "Final file: ${FINAL_NAME} ${SIZE}"
    fi
}
########################################
get_file() {
    NAME=$1
    if [[ -z ${NAME} ]]; then
        echo >&2 "Missing argument: file name"
        exit 1
    fi
    check_dumpapp_avail
    download_file "${NAME}"
}
########################################
move_file() {
    adb shell "chmod 777 $1"
    adb pull $1
    adb shell "rm -f $1"
}
########################################
move_extract_file() {
    PREFIX=$1
    PKG=$2
    REMOTE_PATH=$3
    TAR_FILE=${PKG}.${PREFIX}.tar
    TAR_PATH=/sdcard/${TAR_FILE}
    adb shell "cd ${REMOTE_PATH}/${PREFIX} && tar cvf ${TAR_PATH} . > /dev/null"
    move_file ${TAR_PATH}
    mkdir ${PKG}/${PREFIX}
    tar -xf ${TAR_FILE} -C ${PKG}/${PREFIX}
    rm -f ${TAR_FILE}
}
########################################
check_package_name() {
    if [[ -z "$1" ]]; then
        echo >&2 "Missing argument: package name"
        exit 1
    fi
}
########################################
get_data() {
    check_package_name "$1"
    PKG=$1

    REMOTE_PATH=/data/data/${PKG}
    TAR_FILE=${PKG}.tar
    TAR_PATH=/sdcard/${TAR_FILE}
    adb root
    adb shell "cd ${REMOTE_PATH} && tar cvf ${TAR_PATH} . --exclude=cache  --exclude=files > /dev/null"
    move_file ${TAR_PATH}
    mkdir ${PKG}
    tar -xf "${TAR_FILE}" -C ${PKG}
    rm -f ${TAR_FILE}

    move_extract_file cache ${PKG} ${REMOTE_PATH}
    move_extract_file files ${PKG} ${REMOTE_PATH}

    DB_PATH=${PKG}/databases
    for FILE in $(find ${DB_PATH} -type f -name "*db" 2>/dev/null); do
        sqlite3 ${FILE} VACUUM
    done
}
########################################
backup_data() {
    check_package_name "$1"
    PKG=$1
    FILE_NAME=${PKG}.tar
    REMOTE_FILE=/tmp/${FILE_NAME}
    echo "Archive data to ${REMOTE_FILE} at android device"
    echo adb shell "cd /data/data && tar cvf ${REMOTE_FILE} ${PKG}"
    exit 1
    RC=$?
    if [[ ${RC} != 0 ]]; then
        exit ${RC}
    fi
    echo "Pull archive to ${FILE_NAME} at local device"
    adb pull "${REMOTE_FILE}" .
    adb shell rm -f "${REMOTE_FILE}"
}
########################################
print_prefs() {
    check_package_name "$1"
    adb shell "cat /data/data/$1/shared_prefs/*.xml"
}
########################################
restore_data() {
    check_package_name "$1"
    PKG=$1
    FILE_NAME=${PKG}.tar
    LOC_FILE=${FILE_NAME}
    echo "Push file ${LOC_FILE}"
    REMOTE_FILE=/tmp/${LOC_FILE}
    adb push "${LOC_FILE}" "${REMOTE_FILE}"
    RC=$?
    if [[ ${RC} != 0 ]]; then
        exit ${RC}
    fi
    echo "Extrach archive from ${REMOTE_FILE} at android device"
    adb shell "cd /data/data && tar xvf ${REMOTE_FILE}"
    adb shell "rm -f ${REMOTE_FILE}"
}
########################################
uninstall_package() {
    PACKAGE=$1
    echo "Uninstall package \"${PACKAGE}\""
    adb uninstall "${PACKAGE}"
}
########################################
uninstall_app() {
    TARGET=$1
    if [[ -z ${TARGET} ]]; then
        echo >&2 "Missing argument: package name or local apk-file"
        exit 1
    fi
    APK=$(echo "${TARGET,,}")
    if [[ ${APK} == *.apk ]]; then
        if [[ ! -f ${TARGET} ]]; then
            echo >&2 "File ${TARGET} not found"
            exit 1
        fi
        PACKAGE_INFO=$(aapt dump badging "${TARGET}" | grep -E "package|launchable-activity")
        PACKAGE=$("${PACKAGE_INFO}" | sed "s/.*package: name='\([^']*\)'.*/\1/")
        if [[ -z ${PACKAGE} ]]; then
            echo >&2 "Package name not found in file ${TARGET}"
            exit 1
        fi
    else
        PACKAGE=${TARGET}
    fi
    uninstall_package "${PACKAGE}"
}
########################################
pull_apk() {
    check_package_name "$1"
    PKG=$1

    RES=$(adb shell pm path "${PKG}" | grep -v "split")
    PTH=$(echo "${RES}" | grep -Po 'package:\K[^"]+' | tr -d '\r')
    if [ -z "${PTH}" ]; then
        echo >&2 "Package not found"
        exit 1
    fi
    echo "APK path: '${PTH}'"
    adb pull ${PTH} "${PKG}.apk"
}
########################################
send_action() {
    ACTION=$1
    if [ -z ${ACTION} ]; then
        echo >&2 "Missing argument: action"
        exit 1
    fi
    if [ ${ACTION} == ${ACTION_BOOT} ]; then
        VALUE="android.intent.action.${ACTION_BOOT_V}"
    else
        VALUE=${ACTION}
    fi
    adb shell am broadcast -a "${VALUE}"
}
########################################
print_focused_wnd() {
    adb shell dumpsys window windows | grep -E 'mCurrentFocus|mFocusedApp'
}
########################################
change_wifi_state() {
    FLAG=$1
    if [[ -z ${FLAG} ]]; then
        echo >&2 "Missing argument: flag"
        exit 1
    fi
    FLAG=$(echo "${FLAG,,}")
    if [[ ${FLAG} == "on" ]]; then
        adb shell svc wifi enable
    elif [[ ${FLAG} == "off" ]]; then
        adb shell svc wifi disable
    else
        echo >&2 "Unknown flag value. Expected on|off"
        exit 1
    fi
}
########################################
print_dev_props() {
    DEVICES=$(get_connected_devices)
    for DEV in ${DEVICES}; do
        VER=$(adb -s "${DEV}" shell getprop | grep --color=never "model\|version.sdk\|manufacturer\|hardware\|platform\|revision\|serialno\|product.name\|brand")
        echo "${VER}"
    done | column -t
}
########################################
get_cert_pin() {
    SERVER=$1
    if [[ -z ${SERVER} ]]; then
        echo >&2 "Missing argument: server (for example: mozilla.org)"
        exit 1
    fi
    CERT_FILE=/tmp/${SERVER}.crt
    echo | openssl s_client -servername "${SERVER}" -connect "${SERVER}":443 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > "${CERT_FILE}"
    SHA256=$(openssl x509 -in "${CERT_FILE}" -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64)
    echo -e "\nsha256/${SHA256}"
}
########################################
sync_time_with_host() {
  CUR_TIME=$(date +%m%d%H%M%Y.%S)
  adb shell su 0 "date ${CUR_TIME}"
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
    TMP_FILE=$(mktemp /tmp/"${ONLY_NAME}".XXXXXX)
    echo '_android_tools()
{
  opts=$('$(realpath "$0")' --keywords)
  local cur prev
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
  return 0
}
complete -o nospace -F _android_tools '"${FILE_NAME}"'' >"${TMP_FILE}"
    if [[ $(whoami) == "schumi" ]]; then
        echo "complete -o nospace -F _android_tools at" >>"${TMP_FILE}"
    fi
    sudo mv "${TMP_FILE}" "${FILE}"
    sudo chown root:root "${FILE}"
    sudo chmod 644 "${FILE}"
}
########################################
complete_uninstall() {
    FILE=$(get_complete_file)
    sudo rm "${FILE}"
}
######################################## MAIN ########################################
if [[ "$@" == *"${K_HLP}"* ]] || [[ "$#" -eq 0 ]]; then
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
        get_db "${arg#*=}"
        exit 0
        ;;
    ${K_GET_FILE}=*)
        get_file "${arg#*=}"
        exit 0
        ;;
    ${K_GET_PKG_DATA}=*)
        get_data "${arg#*=}"
        exit 0
        ;;
    ${K_DATA_BACKUP}=*)
        backup_data "${arg#*=}"
        exit 0
        ;;
    ${K_PREFS}=*)
        print_prefs "${arg#*=}"
        exit 0
        ;;
    ${K_DATA_RESTORE}=*)
        restore_data "${arg#*=}"
        exit 0
        ;;
    ${K_UNINSTALL}=*)
        uninstall_app "${arg#*=}"
        exit 0
        ;;
    ${K_PULL_APK}=*)
        pull_apk "${arg#*=}"
        exit 0
        ;;
    ${K_SEND_ACTION}=*)
        send_action "${arg#*=}"
        exit 0
        ;;
    ${K_FOCUSED_WND})
        print_focused_wnd
        exit 0
        ;;
    ${K_WIFI}=*)
        change_wifi_state "${arg#*=}"
        exit 0
        ;;
    ${K_DEV_PROPS})
        print_dev_props
        exit 0
        ;;
    ${K_GET_CERT_PIN}=*)
        get_cert_pin "${arg#*=}"
        exit 0
        ;;
    ${K_SYNC_TIME_WITH_HOST})
        sync_time_with_host
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
        echo >&2 "Unknown argument: ${arg}"
        exit 1
        ;;
    esac
done
