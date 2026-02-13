#!/bin/bash

set -euo pipefail

DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

CURRENT_THEME_FILE="$DATA_HOME/current-theme"
ROFI_THEME="$CONFIG_HOME/rofi/wallSelect.rasi"

require_command() {
  local cmd="$1"

  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command not found: $cmd" >&2
    exit 1
  fi
}

for cmd in rofi convert swww; do
  require_command "$cmd"
done

if [[ ! -r "$CURRENT_THEME_FILE" ]]; then
  echo "error: current theme file not found: $CURRENT_THEME_FILE" >&2
  exit 1
fi

IFS= read -r current_theme <"$CURRENT_THEME_FILE" || true
current_theme="${current_theme%$'\r'}"

if [[ -z "$current_theme" ]]; then
  echo "error: current theme is empty: $CURRENT_THEME_FILE" >&2
  exit 1
fi

wall_dir="$DATA_HOME/themes/$current_theme/wallpapers"
cache_dir="$CACHE_HOME/jp/$current_theme"

if [[ ! -d "$wall_dir" ]]; then
  echo "error: wallpaper directory not found: $wall_dir" >&2
  exit 1
fi

if [[ ! -f "$ROFI_THEME" ]]; then
  echo "error: rofi theme not found: $ROFI_THEME" >&2
  exit 1
fi

mkdir -p "$cache_dir"

shopt -s nullglob nocaseglob
wallpapers=("$wall_dir"/*.{jpg,jpeg,png,webp})
shopt -u nullglob nocaseglob

if [[ "${#wallpapers[@]}" -eq 0 ]]; then
  echo "error: no wallpapers found in: $wall_dir" >&2
  exit 1
fi

mapfile -d '' -t wallpapers < <(printf '%s\0' "${wallpapers[@]}" | LC_ALL=C sort -z)

for image_path in "${wallpapers[@]}"; do
  file_name="$(basename -- "$image_path")"
  thumb_path="$cache_dir/$file_name"

  if [[ ! -f "$thumb_path" || "$image_path" -nt "$thumb_path" ]]; then
    if ! convert -strip "$image_path" -thumbnail 500x500^ -gravity center -extent 500x500 "$thumb_path"; then
      echo "warning: failed to generate thumbnail: $image_path" >&2
    fi
  fi
done

rofi_rows() {
  local image_path file_name thumb_path

  for image_path in "${wallpapers[@]}"; do
    file_name="$(basename -- "$image_path")"
    thumb_path="$cache_dir/$file_name"
    printf '%s\0icon\x1f%s\n' "$file_name" "$thumb_path"
  done
}

rofi_command=(
  rofi
  -no-config
  -dmenu
  -i
  -show-icons
  -theme "$ROFI_THEME"
)

if ! wall_selection="$(rofi_rows | "${rofi_command[@]}")"; then
  exit 0
fi

[[ -n "$wall_selection" ]] || exit 0

selected_wallpaper="$wall_dir/$wall_selection"
if [[ ! -f "$selected_wallpaper" ]]; then
  echo "error: selected wallpaper not found: $selected_wallpaper" >&2
  exit 1
fi

exec swww img -t any --transition-fps 60 "$selected_wallpaper"
