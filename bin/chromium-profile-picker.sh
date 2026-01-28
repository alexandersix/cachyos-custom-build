#!/bin/bash

set -euo pipefail

CONFIG_DIR="$HOME/.config/chromium"
LOCAL_STATE="$CONFIG_DIR/Local State"
ROFI_PROMPT="Chromium profile"

if ! command -v rofi >/dev/null 2>&1; then
  echo "rofi not found in PATH"
  exit 1
fi

if ! command -v chromium >/dev/null 2>&1; then
  echo "chromium not found in PATH"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq not found in PATH"
  exit 1
fi

get_profiles() {
  if [[ ! -d "$CONFIG_DIR" ]]; then
    echo "Chromium config directory not found: $CONFIG_DIR" >&2
    return 1
  fi

  if [[ ! -f "$LOCAL_STATE" ]]; then
    echo "Chromium Local State not found: $LOCAL_STATE" >&2
    return 1
  fi

  jq -r '.profile.info_cache // {} | to_entries[] | "\(.value.name // .key)\t\(.key)"' "$LOCAL_STATE" |
    while IFS=$'\t' read -r name dir_name; do
      if [[ -d "$CONFIG_DIR/$dir_name" ]]; then
        printf '%s\t%s\n' "$name" "$dir_name"
      fi
    done
}

profiles_output=$(get_profiles) || exit 1

if [[ -z "$profiles_output" ]]; then
  echo "No Chromium profiles found in $CONFIG_DIR"
  exit 1
fi

mapfile -t profiles <<< "$profiles_output"

names=()
dirs=()
for line in "${profiles[@]}"; do
  if [[ "$line" == *$'\t'* ]]; then
    name="${line%%$'\t'*}"
    dir_name="${line#*$'\t'}"
  else
    name="$line"
    dir_name="$line"
  fi
  names+=("$name")
  dirs+=("$dir_name")
done

selection=$(printf '%s\n' "${names[@]}" | rofi -dmenu -i -p "$ROFI_PROMPT" -format 'i')

if [[ -z "$selection" ]]; then
  exit 0
fi

if [[ "$selection" =~ ^[0-9]+$ ]]; then
  if ((selection < 0 || selection >= ${#dirs[@]})); then
    echo "Invalid profile selection: $selection"
    exit 1
  fi
  profile_dir="${dirs[$selection]}"
else
  profile_dir=""
  for i in "${!names[@]}"; do
    if [[ "${names[$i]}" == "$selection" ]]; then
      profile_dir="${dirs[$i]}"
      break
    fi
  done

  if [[ -z "$profile_dir" ]]; then
    echo "Profile not found: $selection"
    exit 1
  fi
fi

exec chromium --new-window --profile-directory="$profile_dir"
