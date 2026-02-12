#!/bin/bash

set -euo pipefail

ROFI_PROMPT="Theme"
SYNC_ROOT=0

usage() {
  echo "usage: $(basename "$0") [--sync-root]" >&2
}

for arg in "$@"; do
  case "$arg" in
  --sync-root)
    SYNC_ROOT=1
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "error: unexpected argument: $arg" >&2
    usage
    exit 1
    ;;
  esac
done

if ! command -v rofi >/dev/null 2>&1; then
  echo "rofi not found in PATH"
  exit 1
fi

resolve_path() {
  local path="$1"

  if command -v realpath >/dev/null 2>&1; then
    realpath "$path"
  elif command -v readlink >/dev/null 2>&1; then
    readlink -f "$path"
  else
    echo "$path"
  fi
}

SCRIPT_PATH="$(resolve_path "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
APPLY_THEME_SCRIPT="$SCRIPT_DIR/apply-theme.sh"

if [[ ! -f "$APPLY_THEME_SCRIPT" ]]; then
  echo "apply-theme.sh not found: $APPLY_THEME_SCRIPT" >&2
  exit 1
fi

DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
THEMES_DIR="$DATA_HOME/themes"

if [[ ! -d "$THEMES_DIR" ]]; then
  echo "Themes directory not found: $THEMES_DIR" >&2
  exit 1
fi

themes=()
for dir in "$THEMES_DIR"/*; do
  if [[ -d "$dir" ]]; then
    themes+=("$(basename "$dir")")
  fi
done

if [[ ${#themes[@]} -eq 0 ]]; then
  echo "No themes found in $THEMES_DIR"
  exit 1
fi

mapfile -t themes < <(printf '%s\n' "${themes[@]}" | LC_ALL=C sort)

selection=$(printf '%s\n' "${themes[@]}" | rofi -dmenu -i -p "$ROFI_PROMPT" -format 'i')

if [[ -z "$selection" ]]; then
  exit 0
fi

if [[ "$selection" =~ ^[0-9]+$ ]]; then
  if ((selection < 0 || selection >= ${#themes[@]})); then
    echo "Invalid theme selection: $selection" >&2
    exit 1
  fi
  theme_name="${themes[$selection]}"
else
  theme_name=""
  for name in "${themes[@]}"; do
    if [[ "$name" == "$selection" ]]; then
      theme_name="$name"
      break
    fi
  done

  if [[ -z "$theme_name" ]]; then
    echo "Theme not found: $selection" >&2
    exit 1
  fi
fi

apply_args=("$theme_name")
if [[ "$SYNC_ROOT" -eq 1 ]]; then
  apply_args+=("--sync-root")
fi

exec "$APPLY_THEME_SCRIPT" "${apply_args[@]}"
