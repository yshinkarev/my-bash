#!/usr/bin/env bash

export PYTHONDONTWRITEBYTECODE=1

########################################
configure() {
  DIR="${HOME}/.mitmproxy"
  if [ ! -d "${DIR}" ]; then
    echo "Create directory ${DIR}"
    mkdir "${DIR}"
  fi

  CONFIG_FILE="${DIR}/config.yaml"
  if [ ! -f "${CONFIG_FILE}" ]; then
    echo "Create file ${CONFIG_FILE}"

    echo "ssl_insecure: true
console_flowlist_layout: table
console_palette: solarized_dark
console_mouse: false
console_focus_follow: true" >"${CONFIG_FILE}"
  fi

  CURRENT_PATH=$(dirname "$0")
  YAML_SAMPLE_FILE=${CURRENT_PATH}/mitm.yaml.example
  YAML_FILE=${CURRENT_PATH}/mitm.yaml

  if [ ! -e "${YAML_FILE}" ]; then
    echo "Copy ${YAML_FILE} file"
    cp "${YAML_SAMPLE_FILE}" "${YAML_FILE}"
  fi
}
########################################
for arg in "$@"; do
  case ${arg} in
  "--configure")
    configure
    exit 0
    ;;
  esac
done

mitmproxy -s ./mitm.py