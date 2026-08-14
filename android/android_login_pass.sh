#!/usr/bin/env bash

set -euo pipefail

LOGIN="${1:?Login is required}"
PASS="${2:?Password is required}"

input_text() {
  local text="$1"

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

  adb shell input text "$text"
}

dump_ui() {
  local local_dump="$1"
  local dump_path="/sdcard/window_dump.xml"

  adb shell uiautomator dump "$dump_path" >/dev/null
  adb shell cat "$dump_path" | tr -d '\r' > "$local_dump"
}

read_targets() {
  local local_dump="$1"

  python3 -c '
import re
import sys
import xml.etree.ElementTree as ET

BOUNDS_RE = re.compile(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]")


def parse_bounds(bounds):
    match = BOUNDS_RE.fullmatch(bounds)
    if not match:
        return None
    left, top, right, bottom = map(int, match.groups())
    return left, top, right, bottom


def center_y(bounds):
    parsed = parse_bounds(bounds)
    if not parsed:
        return 0
    return (parsed[1] + parsed[3]) // 2


def bottom_y(bounds):
    parsed = parse_bounds(bounds)
    if not parsed:
        return 0
    return parsed[3]

root = ET.parse(sys.argv[1]).getroot()
editable_nodes = []
submit_candidates = []

for node in root.iter("node"):
    bounds = node.attrib.get("bounds")
    parsed_bounds = parse_bounds(bounds or "")
    if not parsed_bounds:
        continue

    class_name = node.attrib.get("class", "")
    editable = node.attrib.get("editable") == "true"
    password = node.attrib.get("password") == "true"
    clickable = node.attrib.get("clickable") == "true"
    is_button_like = class_name.endswith("Button") or class_name.endswith("TextView")

    if editable or password or class_name.endswith("EditText"):
        editable_nodes.append((password, bounds))

    if clickable or is_button_like:
        submit_candidates.append(bounds)

password_bounds = ""
for is_password, bounds in editable_nodes:
    if is_password:
        password_bounds = bounds
        break

if not password_bounds and len(editable_nodes) >= 2:
    password_bounds = editable_nodes[1][1]

password_bottom = bottom_y(password_bounds)
submit_bounds = ""
below_submit_candidates = [bounds for bounds in submit_candidates if center_y(bounds) > password_bottom]

if below_submit_candidates:
    submit_bounds = min(below_submit_candidates, key=center_y)
elif submit_candidates:
    submit_bounds = submit_candidates[-1]

print(password_bounds)
print(submit_bounds)
' "$local_dump"
}

tap_bounds() {
  local bounds="$1"
  local target_name="$2"

  if [[ -z "$bounds" ]]; then
    echo "$target_name was not found in UI hierarchy." >&2
    return 1
  fi

  if [[ "$bounds" =~ \[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\] ]]; then
    local x=$(( (BASH_REMATCH[1] + BASH_REMATCH[3]) / 2 ))
    local y=$(( (BASH_REMATCH[2] + BASH_REMATCH[4]) / 2 ))
    adb shell input tap "$x" "$y"
    sleep 0.2
    return 0
  fi

  echo "Unexpected $target_name bounds: $bounds" >&2
  return 1
}

local_dump="$(mktemp)"
dump_ui "$local_dump"
mapfile -t targets < <(read_targets "$local_dump")
rm -f "$local_dump"

password_bounds="${targets[0]:-}"
submit_bounds="${targets[1]:-}"

input_text "$LOGIN"
tap_bounds "$password_bounds" "password field"
input_text "$PASS"

# Use direct tap. Navigation/space key events may append whitespace to the password field.
tap_bounds "$submit_bounds" "submit button" || adb shell input keyevent KEYCODE_ENTER
