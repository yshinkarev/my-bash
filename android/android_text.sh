#!/usr/bin/env bash

set -euo pipefail

if (( $# == 0 )); then
  echo "Text is required." >&2
  exit 1
fi

text="$*"
text="${text// /%s}"
text="${text//\\/\\\\}"
text="${text//!/\\!}"
text="${text//\(/\\(}"
text="${text//\)/\\)}"
text="${text//\&/\\&}"
text="${text//\|/\\|}"
text="${text//\;/\\;}"
text="${text//\</\\<}"
text="${text//\>/\\>}"
text="${text//\*/\\*}"
text="${text//#/\\#}"

run_on_each_device() {
  local devices adb_serial state physical_serial pid
  local physical_serials=$'\n'
  local device_serials=()
  local pids=()
  local status=0

  devices="$(adb devices)"

  while IFS=$'\t' read -r adb_serial state; do
    [[ "$state" == "device" ]] || continue

    if ! physical_serial="$(adb -s "$adb_serial" shell getprop ro.serialno </dev/null | tr -d '\r\n')"; then
      physical_serial="$adb_serial"
    fi
    [[ -n "$physical_serial" ]] || physical_serial="$adb_serial"

    case "$physical_serials" in
      *$'\n'"$physical_serial"$'\n'*) continue ;;
    esac

    physical_serials+="$physical_serial"$'\n'
    device_serials+=("$adb_serial")
  done <<< "$devices"

  for adb_serial in "${device_serials[@]}"; do
    adb -s "$adb_serial" "$@" &
    pids+=("$!")
  done

  for pid in "${pids[@]}"; do
    if ! wait "$pid"; then
      status=1
    fi
  done

  return "$status"
}

run_on_each_device shell input text "$text"
