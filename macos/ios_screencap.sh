#!/usr/bin/env bash

set -Eeuo pipefail

DIR=.
TO_JPG=0
NAME=
ADD_TIMESTAMP=0
TO_CLIPBOARD=0
UDID=
FORCE=0
AUTO_MOUNT=1
XCODE_APP=
TEMP_DIR=

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]
Make a screenshot from a USB-connected iPhone using pymobiledevice3 DVT.

  -d,  --directory DIR  Output directory (default: current directory)
  -n,  --name NAME      Output filename without extension (default: device name)
  -u,  --udid UDID      Target iPhone UDID
  -x,  --xcode PATH     Xcode.app used to find a Developer Disk Image
  -tj, --to-jpg         Convert screenshot to JPEG using macOS sips
  -cb, --clipboard      Copy screenshot to the macOS clipboard instead of saving it
  -at, --add-timestamp  Add current timestamp to the filename
  -f,  --force          Overwrite an existing output file
       --no-auto-mount  Do not auto-mount a DDI after a failed screenshot attempt
  -h,  --help           Show this help and exit

Values may also be passed with '=':
  --directory=/tmp --name=screenshot --udid=UDID --xcode=/Applications/Xcode.app
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

discover_usb_udids() {
    local discovered=
    local simple_list=

    if command -v idevice_id >/dev/null 2>&1; then
        discovered=$(idevice_id -l 2>/dev/null || true)
    fi

    if [[ -z "$discovered" ]]; then
        simple_list=$(pymobiledevice3 usbmux list --usb --simple 2>/dev/null || true)
        discovered=$(printf '%s\n' "$simple_list" \
            | tr ',' '\n' \
            | sed -E 's/[]["[:space:]]//g; /^$/d')
    fi

    printf '%s\n' "$discovered" | awk 'NF && !seen[$0]++ { print }'
}

take_screenshot() {
    local output_file=$1
    local signature

    rm -f -- "$output_file"
    pymobiledevice3 developer dvt screenshot "$output_file" --udid "$UDID" || return 1
    [[ -s "$output_file" ]] || return 1

    signature=$(LC_ALL=C od -An -tx1 -N8 "$output_file" | tr -d '[:space:]')
    [[ "$signature" == "89504e470d0a1a0a" ]]
}

mount_developer_image() {
    local mount_command=(pymobiledevice3 mounter auto-mount --udid "$UDID")

    if [[ -n "$XCODE_APP" ]]; then
        mount_command+=(--xcode "$XCODE_APP")
    fi

    echo "Mounting Developer Disk Image for $UDID..." >&2
    "${mount_command[@]}"
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
    -u | --udid)
        (( $# >= 2 )) || die "$1 requires a value"
        UDID=$2
        shift 2
        ;;
    -u=* | --udid=*)
        UDID=${1#*=}
        shift
        ;;
    -x | --xcode)
        (( $# >= 2 )) || die "$1 requires a value"
        XCODE_APP=$2
        shift 2
        ;;
    -x=* | --xcode=*)
        XCODE_APP=${1#*=}
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
    --no-auto-mount)
        AUTO_MOUNT=0
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
require_command pymobiledevice3

if [[ -n "$XCODE_APP" ]]; then
    [[ -d "$XCODE_APP" ]] || die "Xcode application not found: $XCODE_APP"
    [[ -d "$XCODE_APP/Contents/Developer" ]] || die "invalid Xcode application: $XCODE_APP"
fi

if [[ -z "$UDID" ]]; then
    AVAILABLE_DEVICES=$(discover_usb_udids)
    DEVICE_COUNT=$(printf '%s\n' "$AVAILABLE_DEVICES" | awk 'NF { count++ } END { print count + 0 }')

    case "$DEVICE_COUNT" in
    0)
        die "no USB-connected iPhone found; unlock it and confirm trust"
        ;;
    1)
        UDID=$AVAILABLE_DEVICES
        ;;
    *)
        printf 'Connected iPhone UDIDs:\n%s\n' "$AVAILABLE_DEVICES" >&2
        die "multiple iPhones found; select one with --udid"
        ;;
    esac
fi

if [[ -z "$NAME" ]]; then
    if command -v ideviceinfo >/dev/null 2>&1; then
        NAME=$(ideviceinfo -u "$UDID" -k DeviceName 2>/dev/null || true)
    fi
    [[ -n "$NAME" ]] || NAME=iPhone
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
    require_command sips
fi

FINAL_FILE_NAME="${BASE_PATH}.${FORMAT}"

if (( TO_CLIPBOARD )); then
    require_command osascript
    TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/ios-screencap.XXXXXX")
else
    mkdir -p -- "$DIR"
    [[ -d "$DIR" && -w "$DIR" ]] || die "output directory is not writable: $DIR"

    if [[ -e "$FINAL_FILE_NAME" ]] && (( ! FORCE )); then
        die "output file already exists (use --force to overwrite): $FINAL_FILE_NAME"
    fi

    TEMP_DIR=$(mktemp -d "$DIR/.ios-screencap.XXXXXX")
fi

trap cleanup EXIT

PNG_FILE=$TEMP_DIR/screenshot.png
if ! take_screenshot "$PNG_FILE"; then
    if (( ! AUTO_MOUNT )); then
        die "failed to capture screenshot; check USB connection, trust, Developer Mode and mounted DDI"
    fi

    echo "Initial screenshot failed; trying to mount a compatible Developer Disk Image..." >&2
    mount_developer_image || die "failed to mount a compatible Developer Disk Image"
    take_screenshot "$PNG_FILE" \
        || die "failed to capture screenshot after mounting DDI; unlock the iPhone and try again"
fi

READY_FILE=$PNG_FILE
if (( TO_JPG )); then
    JPG_FILE=$TEMP_DIR/screenshot.jpg
    sips -s format jpeg "$PNG_FILE" --out "$JPG_FILE" >/dev/null \
        || die "failed to convert screenshot to JPEG"
    [[ -s "$JPG_FILE" ]] || die "sips returned an empty JPEG file"
    READY_FILE=$JPG_FILE
fi

if (( TO_CLIPBOARD )); then
    copy_to_clipboard "$READY_FILE" "$FORMAT" || die "failed to copy screenshot to clipboard"
    echo "Copied screenshot to clipboard"
else
    mv -f -- "$READY_FILE" "$FINAL_FILE_NAME"
    echo "$FINAL_FILE_NAME"
fi
