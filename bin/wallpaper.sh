#!/bin/bash
set -euo pipefail

usage() {
  echo "usage: $(basename "$0") <wallpaper-dir>" >&2
}

if [[ "$#" -ne 1 ]]; then
  wallpaper_dir="$HOME/.local/share/themes/$(cat $HOME/.local/share/current-theme)/wallpapers"
else
  wallpaper_dir="$1"
fi

if [[ ! -d "$wallpaper_dir" ]]; then
  echo "error: wallpaper directory not found: $wallpaper_dir" >&2
  exit 1
fi

current_wallpaper=""
current_wallpaper_name=""
wallpapers=()
sorted_wallpapers=()

shopt -s nullglob nocaseglob
wallpapers=("$wallpaper_dir"/*.{png,jpg,jpeg,webp,gif,bmp})

if [[ "${#wallpapers[@]}" -eq 0 ]]; then
  echo "error: no wallpapers found in: $wallpaper_dir" >&2
  exit 1
fi

while IFS= read -r candidate; do
  if [[ -f "$candidate" ]]; then
    sorted_wallpapers+=("$candidate")
  fi
done < <(printf '%s\n' "${wallpapers[@]}" | LC_ALL=C sort -V)

wallpapers=("${sorted_wallpapers[@]}")

if [[ "${#wallpapers[@]}" -eq 0 ]]; then
  echo "error: no wallpaper files found in: $wallpaper_dir" >&2
  exit 1
fi

while IFS= read -r query_line; do
  if [[ "$query_line" =~ image:[[:space:]](.+)$ ]]; then
    current_wallpaper="${BASH_REMATCH[1]}"
    break
  fi
done < <(swww query 2>/dev/null || true)

if [[ -n "$current_wallpaper" ]]; then
  current_wallpaper_name="$(basename -- "$current_wallpaper")"
fi

selected="${wallpapers[0]}"

for i in "${!wallpapers[@]}"; do
  candidate="${wallpapers[$i]}"

  if [[ "$candidate" == "$current_wallpaper" ]] || [[ -n "$current_wallpaper_name" && "$(basename -- "$candidate")" == "$current_wallpaper_name" ]]; then

    next_index=$(((i + 1) % ${#wallpapers[@]}))
    selected="${wallpapers[$next_index]}"
    break
  fi
done

swww img -t any --transition-fps 60 "$selected"
