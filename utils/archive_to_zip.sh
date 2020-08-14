#!/usr/bin/env bash

DIRECTORY=
VERBOSE=0
DELETE=0
INSTALLED_7Z_CHECKED=0
INSTALLED_UNRAR_CHECKED=0
########################################
K_DIRECTORY="--directory"
K_DELETE="--delete"
K_VERBOSE="--verbose"
K_HLP="--help"
########################################
show_help() {
  cat <<EOF
Usage: $(basename "$0") [file] <command>
Repack rar/7z archive file to zip archive.

  ${K_DIRECTORY}          Repack recursevily all archives from directory
  ${K_DELETE}             Delete original archives
  ${K_VERBOSE}            Make the operation more talkative
  ${K_HLP}               Print this help and exit
EOF
  echo
}
########################################
check_installed_app() {
  which "$1" >/dev/null
  if [ $? -ne 0 ]; then
    echo >&2 "$1 must be installed before running this script"
    exit 1
  fi
}
########################################
check_installed_7z() {
  [ ${INSTALLED_7Z_CHECKED} == 1 ] && exit 1
  INSTALLED_7Z_CHECKED=1
  check_installed_app 7z
}
########################################
check_installed_unrar() {
  [ ${INSTALLED_UNRAR_CHECKED} == 1 ] && exit 1
  INSTALLED_UNRAR_CHECKED=1
  check_installed_app unrar
}
########################################
print() {
  if [ ${VERBOSE} == 1 ]; then
    echo "$1"
  fi
}
########################################
repack() {
  ARC="$1"
  FILE_NAME=$(basename "$ARC"); EXT="${FILE_NAME##*.}"; EXT=${EXT,,}
  if [ "${EXT}" != "rar" ] && [ "${EXT}" != "7z" ]; then
    echo >&2 "Unknown archive type '${EXT}' for file $(basename "$FILE_NAME")"
    exit 1
  fi

  SUFFIX=$(basename "$0"); SUFFIX="${SUFFIX%.*}"
  TMP_DIR=$(mktemp -d --suff _"${SUFFIX}")
  print "Create temp directory: ${TMP_DIR}"
  pushd "${TMP_DIR}" >/dev/null

  print "Unpack archive ${ARC}"
  if [ "${EXT}" == "rar" ]; then
    unrar x -inul "${ARC}"
  else
    7z x -bd -y "${ARC}" > /dev/null
  fi

  if [ ${DELETE} == 1 ]; then
    print "Delete original archive ${ARC}"
    rm -f "${ARC}"
  fi

  ZIP_FILE=${1%.*}.zip
  print "Pack to zip archive $ZIP_FILE"
  zip -9 -r -q "$ZIP_FILE" .
  popd >/dev/null

  print "Remove temp directory ${TMP_DIR}"
  rm -rf "${TMP_DIR}"

  ZI_FILE_SIZE=$(numfmt --to=iec-i --suffix=B --format="%.1f" $(stat -c%s "${ZIP_FILE}"))
  FILE_NAME=$(basename "${ZIP_FILE}")
  echo "${ARC} => ${FILE_NAME} (${ZI_FILE_SIZE})"
}
########################################
repack_in_directory() {
  OIFS="$IFS"; IFS=$'\n'
  for FILE in $(find ${DIRECTORY} -type f -name "*.rar" -or -name "*.7z" 2>/dev/null); do
    repack "${FILE}"
  done
  IFS="$OIFS"
}
######################################## MAIN ########################################
if [[ "$@" == *"${K_HLP}"* ]] || [[ "$#" -eq 0 ]]; then
  show_help
  exit 0
fi

for ARG in "$@"; do
  case ${ARG} in
  ${K_VERBOSE})
    VERBOSE=1
    shift
    ;;
  ${K_DELETE})
    DELETE=1
    shift
    ;;
  ${K_DIRECTORY}=*)
    DIRECTORY=${ARG#*=}
    shift
    ;;
  *)
    FILE=${ARG}
  esac
done

if [ -z "${FILE}" ] && [ -z "${DIRECTORY}" ]; then
  echo >&2 "Missing argument: file or directory argument"
  exit 1
fi

if [ -n "${FILE}" ]; then
  repack "${FILE}"
fi

if [ -n "${DIRECTORY}" ]; then
  repack_in_directory
fi
