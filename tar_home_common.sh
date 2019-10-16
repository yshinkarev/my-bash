#!/bin/bash

INIT_DIR=$(pwd)
START=$(date +%s)

logStage() {
    END=$(date +%s)
    DIFF=$(($END - $START))
    printf "[%06s] " $((${DIFF} / 60))m$((${DIFF} % 60))s
    echo $@
}

########################################
USER_TO_TAR=$USER
EXCLUDE_FROM=${0%.*}.txt
TARGET_DIR=
TARGET_FILE_NAME=
COMPRESS=

for ARG in "$@"; do
    case $ARG in
    --user=*)
        USER_TO_TAR=${ARG#*=}
        shift
        ;;
    --exclude-from=*)
        EXCLUDE_FROM=${ARG#*=}
        shift
        ;;
    --target-dir=*)
        TARGET_DIR=${ARG#*=}
        shift
        ;;
    --target-filename=*)
        TARGET_FILE_NAME=${ARG#*=}
        shift
        ;;
    --compress=*)
        COMPRESS=${ARG#*=}
        shift
        ;;
    *)
        echo "Unknown argument: ${ARG}"
        exit 1
        ;;
    esac
done
########################################

id "${USER_TO_TAR}" >/dev/null 2>&1
RC=$?
if [[ ${RC} != 0 ]]; then
    echo >&2 "User ${USER_TO_TAR} does not exists"
    exit 1
fi

if [ ! -f "${EXCLUDE_FROM}" ]; then
    echo >&2 "Exclude file ${EXCLUDE_FROM} does not exists"
    exit 1
fi

HOME_PATH=$(eval echo "~${USER_TO_TAR}")
if [ ! -d "${HOME_PATH}" ]; then
    echo >&2 "Home directory ${HOME_PATH} does not exists"
    exit 1
fi

if [ -z "${TARGET_DIR}" ]; then
    TARGET_DIR=${HOME_PATH}
fi

if [ -z "${TARGET_FILE_NAME}" ]; then
    TARGET_FILE_NAME=${USER_TO_TAR}@$(hostname)-$(date +"%Y.%m.%d-%H_%M_%S").tar
    case $COMPRESS in
    *lbzip2)
        TARGET_FILE_NAME=${TARGET_FILE_NAME}.bz
        ;;
    *bpzip2)
        TARGET_FILE_NAME=${TARGET_FILE_NAME}.bz
        ;;
    *pigz)
        TARGET_FILE_NAME=${TARGET_FILE_NAME}.gz
        ;;
    esac
fi

if [ ! -d "${TARGET_DIR}" ]; then
    echo >&2 "Target directory ${TARGET_DIR} does not exists"
    exit 1
fi

DEST_PATH=${TARGET_DIR}/${TARGET_FILE_NAME}
########################################
logStage "Compressing to ${DEST_PATH}"
# Needed, because used cd, but target dir can be set as relative path.
DEST_PATH=$(readlink -f "${DEST_PATH}")
cd "${HOME_PATH}"

if [ -z "${COMPRESS}" ]; then
    tar --exclude-from="${EXCLUDE_FROM}" --exclude=${TARGET_FILE_NAME} -cf "${DEST_PATH}" .
else
    tar --exclude-from="${EXCLUDE_FROM}" --exclude=${TARGET_FILE_NAME} -I "${COMPRESS}" -cf "${DEST_PATH}" .
fi

cd - >/dev/null
logStage "Testing"
if ! tar tf "${DEST_PATH}" &>/dev/null; then
    echo >&2 "Compressed archive does not verified (not found)"
    exit 1
fi

logStage "Calculating MD5"
cd "${TARGET_DIR}"
md5sum "${TARGET_FILE_NAME}" >"${TARGET_FILE_NAME}".md5

END=$(date +%s)
DIFF=$((${END} - ${START}))
logStage "Finished"
cd "${INIT_DIR}" >/dev/null

SCRIPT_NAME=$(basename "$0")
TIME=$(logStage)
notify-send "${SCRIPT_NAME} finished in ${TIME}"
beep.sh
