#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  gradle_deps_transitives.sh <group:artifact[:version]> [--module :app] [--configuration releaseRuntimeClasspath] [--project /path/to/project]

Examples:
  gradle_deps_transitives.sh androidx.navigation:navigation-ui-ktx
  gradle_deps_transitives.sh androidx.navigation:navigation-ui-ktx --module :feature_cir --configuration releaseRuntimeClasspath
  gradle_deps_transitives.sh androidx.navigation:navigation-ui-ktx:2.8.2 --project MyApplication --module :app

Notes:
  - Run it from a Gradle project root, or pass --project.
  - By default it uses module :app and configuration releaseRuntimeClasspath.
  - Output is a unique list of transitive dependencies with resolved versions.
USAGE
}

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

project_dir="$(pwd)"
module=":app"
configuration="releaseRuntimeClasspath"
dependency=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --module)
      module="$2"
      shift 2
      ;;
    --configuration)
      configuration="$2"
      shift 2
      ;;
    --project)
      project_dir="$2"
      shift 2
      ;;
    --*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -z "$dependency" ]]; then
        dependency="$1"
      else
        echo "Unexpected argument: $1" >&2
        usage >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$dependency" ]]; then
  echo "Dependency is required." >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$project_dir/gradlew" ]]; then
  echo "gradlew not found in project: $project_dir" >&2
  exit 1
fi

IFS=':' read -r dep_group dep_artifact dep_version _ <<< "$dependency"
if [[ -z "$dep_group" || -z "$dep_artifact" ]]; then
  echo "Dependency must include at least group:artifact" >&2
  exit 1
fi
input_ga="$dep_group:$dep_artifact"

module_path="$module"
if [[ -n "$module_path" && "$module_path" != :* ]]; then
  module_path=":$module_path"
fi

task="dependencies"
if [[ -n "$module_path" ]]; then
  task="${module_path}:dependencies"
fi

work_file="$(mktemp)"
subtree_file="$(mktemp)"
trap 'rm -f "$work_file" "$subtree_file"' EXIT

(
  cd "$project_dir"
  ./gradlew "$task" --configuration "$configuration"
) > "$work_file"

read -r start_line base_indent < <(
  awk -v dep="$dependency" -v ga="$input_ga" '
  function first_text_pos(s,   i, c) {
    for (i = 1; i <= length(s); i++) {
      c = substr(s, i, 1)
      if (c ~ /[A-Za-z0-9_.]/) return i
    }
    return 0
  }
  function line_matches_target(s, dep, ga) {
    return index(s, dep) || index(s, ga ":")
  }
  {
    if (line_matches_target($0, dep, ga)) {
      cur = first_text_pos($0)
      if (!best_indent || (cur > 0 && cur < best_indent)) {
        best_indent = cur
        best_line = NR
      }
    }
  }
  END {
    if (best_line) print best_line, best_indent
  }
  ' "$work_file"
)

if [[ -z "${start_line:-}" || -z "${base_indent:-}" ]]; then
  echo "Dependency subtree not found: $dependency" >&2
  exit 1
fi

awk -v start="$start_line" -v base="$base_indent" '
function first_text_pos(s,   i, c) {
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (c ~ /[A-Za-z0-9_.]/) return i
  }
  return 0
}
NR < start { next }
NR == start { print; next }
{
  cur = first_text_pos($0)
  if (cur > 0 && cur <= base) exit
  print
}
' "$work_file" > "$subtree_file"

if [[ ! -s "$subtree_file" ]]; then
  echo "Dependency subtree not found: $dependency" >&2
  exit 1
fi

echo "Dependency: $dependency"
echo "Project: $project_dir"
echo "Module: ${module_path:-<root>}"
echo "Configuration: $configuration"
echo

echo "Transitive dependencies:"
awk -v ga="$input_ga" '
function resolved_dep(s,   dep, arr, v) {
  gsub(/^[[:space:]|\\+`-]+/, "", s)
  if (!match(s, /^[A-Za-z0-9_.-]+:[A-Za-z0-9_.-]+:[^[:space:](]+/)) return ""
  dep = substr(s, RSTART, RLENGTH)
  if (match(s, / -> [^[:space:])]+/)) {
    split(dep, arr, ":")
    v = substr(s, RSTART + 4, RLENGTH - 4)
    dep = arr[1] ":" arr[2] ":" v
  }
  return dep
}
NR == 1 { next }
{
  dep = resolved_dep($0)
  if (dep == "") next
  split(dep, parts, ":")
  cur_ga = parts[1] ":" parts[2]
  if (cur_ga == ga) next
  if (!seen[dep]++) print dep
}
' "$subtree_file"
