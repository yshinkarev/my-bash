#!/usr/bin/env bash

########################################
showHelp() {
  cat <<EOF
Usage: $(basename $0) [--mask=FILES_MASK] [--color] [--recursive] [--help]
Show information about apk files filtered by name

  --mask   	Filter filename mask
  --color	Colored output
  --recursive   Search recursively in subdirectories
  --help        Show this help and exit
EOF
}
########################################
FILES_MASK=*.apk
COLOR=0
RECURSIVE=0

if [[ "$@" == *"--help"* ]]; then
  showHelp
  exit 0
fi

for arg in "$@"; do
  case $arg in
  --mask=*)
    FILES_MASK=${arg#*=}
    shift 1
    ;;
  --color)
    COLOR=1
    shift 1
    ;;
  --recursive)
    RECURSIVE=1
    shift 1
    ;;
  *)
    echo >&2 "Unknown argument: $arg"
    exit 1
    ;;
  esac
done
########################################
processFile() {
  PACKAGE_INFO=$(aapt dump badging $1 | grep -E "package|launchable-activity|versionCode")
  PACKAGE=$(echo ${PACKAGE_INFO} | sed "s/.*package: name='\([^']*\)'.*/\1/")
  VERSION=$(echo ${PACKAGE_INFO} | sed "s/.* versionCode='\([^']*\)'.*/\1/")
  VERSION_NAME=$(echo ${PACKAGE_INFO} | sed "s/.* versionName='\([^']*\)'.*/\1/")

  ACTIVITY=$(echo ${PACKAGE_INFO} | sed -e "s/.*launchable-activity: name='\([^']*\)'.*/\1/g")
  if [[ $ACTIVITY == *"package: name"* ]]; then
    ACTIVITY=
  fi
  if [ ${COLOR} == 0 ]; then
    BL=
    GR=
    NC=
  fi

  echo -e "$1 ${BL}${PACKAGE}${NC} ${VERSION} ${VERSION_NAME} ${GR}${ACTIVITY}${NC} $(humanFormat "${SIZE}")"
}
########################################
humanFormat() {
  which numfmt >/dev/null
  if [[ $? -eq 0 ]]; then
    echo $(numfmt --to=iec-i --suffix=B --format="%.1f" $1)
  else
    echo $1
  fi
}
########################################
BL='\033[1;34m'
GR='\033[0;32m'
NC='\033[0m'

if [ ${RECURSIVE} == 1 ]; then
  for APK in $(find . -type f -name "${FILES_MASK}"); do
    processFile $APK
  done
  exit 0
fi

echo "${FILES_MASK}"
for APK in ${FILES_MASK}; do
  processFile "${APK}"
done