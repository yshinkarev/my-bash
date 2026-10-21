#!/usr/bin/env bash

set -Eeuo pipefail

DIR=.
TO_JPG=0
NAME=
ADD_TIMESTAMP=0
TO_CLIPBOARD=0
SERIAL=
FORCE=0
TEMP_DIR=

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]
Make a screenshot from an Android device using adb screencap.

  -d,  --directory DIR  Output directory (default: current directory)
  -n,  --name NAME      Output filename without extension (default: device model)
  -s,  --serial SERIAL  Target adb device serial
  -tj, --to-jpg         Convert screenshot to JPEG
  -cb, --clipboard      Copy screenshot to the macOS clipboard instead of saving it
  -at, --add-timestamp  Add current timestamp to the filename
  -f,  --force          Overwrite an existing output file
  -h,  --help           Show this help and exit

Values may also be passed with '=' for backward compatibility:
  --directory=/tmp --name=screenshot --serial=SERIAL
EOF
}

die() {
    echo "Error: $*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf -- "$TEMP_DIR"
    fi
}

sanitize_name() {
    local value=$1

    value=$(printf '%s' "$value" | tr '\r\n\t' '---')
    value=$(printf '%s' "$value" | sed -E \
        -e 's/\.[Pp][Nn][Gg]$//' \
        -e 's/\.[Jj][Pp][Ee]?[Gg]$//' \
        -e 's#[/\\]+#-#g' \
        -e 's/[[:space:]]+/-/g' \
        -e 's/-+/-/g' \
        -e 's/^-+//' \
        -e 's/-+$//')

    printf '%s' "$value"
}

copy_to_clipboard() {
    local input_file=$1
    local image_format=$2

    if [[ "$image_format" == "jpg" ]]; then
        osascript - "$input_file" <<'APPLESCRIPT'
on run argv
    set imageFile to POSIX file (item 1 of argv)
    set the clipboard to (read imageFile as «class JPEG»)
end run
APPLESCRIPT
    else
        osascript - "$input_file" <<'APPLESCRIPT'
on run argv
    set imageFile to POSIX file (item 1 of argv)
    set the clipboard to (read imageFile as «class PNGf»)
end run
APPLESCRIPT
    fi
}

while (( $# > 0 )); do
    case "$1" in
    -h | --help)
        show_help
        exit 0
        ;;
    -d | --directory)
        (( $# >= 2 )) || die "$1 requires a value"
        DIR=$2
        shift 2
        ;;
    -d=* | --directory=*)
        DIR=${1#*=}
        shift
        ;;
    -n | --name)
        (( $# >= 2 )) || die "$1 requires a value"
        NAME=$2
        shift 2
        ;;
    -n=* | --name=*)
        NAME=${1#*=}
        shift
        ;;
    -s | --serial)
        (( $# >= 2 )) || die "$1 requires a value"
        SERIAL=$2
        shift 2
        ;;
    -s=* | --serial=*)
        SERIAL=${1#*=}
        shift
        ;;
    -tj | --to-jpg)
        TO_JPG=1
        shift
        ;;
    -cb | --clipboard)
        TO_CLIPBOARD=1
        shift
        ;;
    -at | --add-timestamp)
        ADD_TIMESTAMP=1
        shift
        ;;
    -f | --force)
        FORCE=1
        shift
        ;;
    --)
        shift
        (( $# == 0 )) || die "positional arguments are not supported: $*"
        ;;
    *)
        die "unknown argument: $1"
        ;;
    esac
done

[[ -n "$DIR" ]] || die "output directory must not be empty"

require_command adb

ADB_DEVICES_OUTPUT=$(adb devices -l) || die "failed to query adb devices"

if [[ -z "$SERIAL" ]]; then
    AVAILABLE_DEVICES=$(adb devices | awk '
        NR > 1 && $NF == "device" {
            sub(/[[:space:]]+device[[:space:]]*$/, "")
            print
        }
    ') || die "failed to query ready adb devices"
    DEVICE_COUNT=$(printf '%s\n' "$AVAILABLE_DEVICES" | awk 'NF { count++ } END { print count + 0 }')

    case "$DEVICE_COUNT" in
    0)
        printf '%s\n' "$ADB_DEVICES_OUTPUT" >&2
        die "no ready Android devices found"
        ;;
    1)
        SERIAL=$AVAILABLE_DEVICES
        ;;
    *)
        printf '%s\n' "$ADB_DEVICES_OUTPUT" >&2
        die "multiple Android devices found; select one with --serial"
        ;;
    esac
fi

ADB=(adb -s "$SERIAL")
DEVICE_STATE=$("${ADB[@]}" get-state 2>/dev/null) || die "device is unavailable: $SERIAL"
[[ "$DEVICE_STATE" == "device" ]] || die "device is not ready: $SERIAL ($DEVICE_STATE)"

if [[ -z "$NAME" ]]; then
    NAME=$("${ADB[@]}" shell getprop ro.product.model) || die "failed to read device model: $SERIAL"
    NAME=${NAME//$'\r'/}
    NAME=${NAME//$'\n'/}
    [[ -n "$NAME" ]] || NAME=$SERIAL
fi

NAME=$(sanitize_name "$NAME")
[[ -n "$NAME" ]] || die "output filename must not be empty"

BASE_PATH=$DIR/$NAME
if (( ADD_TIMESTAMP )); then
    BASE_PATH="${BASE_PATH}_$(date +'%Y-%m-%d_%H-%M-%S')"
fi

FORMAT=png
if (( TO_JPG )); then
    FORMAT=jpg
fi

FINAL_FILE_NAME="${BASE_PATH}.${FORMAT}"

if (( TO_CLIPBOARD )); then
    require_command osascript
    TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/android-screencap.XXXXXX")
else
    mkdir -p -- "$DIR"
    [[ -d "$DIR" && -w "$DIR" ]] || die "output directory is not writable: $DIR"

    if [[ -e "$FINAL_FILE_NAME" ]] && (( ! FORCE )); then
        die "output file already exists (use --force to overwrite): $FINAL_FILE_NAME"
    fi

    TEMP_DIR=$(mktemp -d "$DIR/.android-screencap.XXXXXX")
fi

trap cleanup EXIT

PNG_FILE=$TEMP_DIR/screenshot.png
if ! "${ADB[@]}" exec-out screencap -p >"$PNG_FILE"; then
    die "failed to capture screenshot from device: $SERIAL"
fi

[[ -s "$PNG_FILE" ]] || die "adb returned an empty screenshot"
PNG_SIGNATURE=$(LC_ALL=C od -An -tx1 -N8 "$PNG_FILE" | tr -d '[:space:]')
[[ "$PNG_SIGNATURE" == "89504e470d0a1a0a" ]] || die "adb output is not a valid PNG screenshot"

READY_FILE=$PNG_FILE
if (( TO_JPG )); then
    JPG_FILE=$TEMP_DIR/screenshot.jpg

    if command -v magick >/dev/null 2>&1; then
        magick "$PNG_FILE" "$JPG_FILE" || die "failed to convert screenshot to JPEG"
    elif command -v convert >/dev/null 2>&1; then
        convert "$PNG_FILE" "$JPG_FILE" || die "failed to convert screenshot to JPEG"
    else
        die "JPEG conversion requires ImageMagick (magick or convert)"
    fi

    [[ -s "$JPG_FILE" ]] || die "JPEG converter returned an empty file"
    READY_FILE=$JPG_FILE
fi

if (( TO_CLIPBOARD )); then
    copy_to_clipboard "$READY_FILE" "$FORMAT" || die "failed to copy screenshot to clipboard"
    echo "Copied screenshot to clipboard"
else
    mv -f -- "$READY_FILE" "$FINAL_FILE_NAME"
    echo "$FINAL_FILE_NAME"
fi
