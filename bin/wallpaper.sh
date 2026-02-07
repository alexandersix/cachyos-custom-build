#!/bin/bash
set -euo pipefail

usage() {
  echo "usage: $(basename "$0") <wallpaper-dir>" >&2
}

if [[ "$#" -ne 1 ]]; then
  usage
  exit 1
fi

wallpaper_dir="$1"

if [[ ! -d "$wallpaper_dir" ]]; then
  echo "error: wallpaper directory not found: $wallpaper_dir" >&2
  exit 1
fi

shopt -s nullglob
wallpapers=("$wallpaper_dir"/*)
shopt -u nullglob

if [[ "${#wallpapers[@]}" -eq 0 ]]; then
  echo "error: no wallpapers found in: $wallpaper_dir" >&2
  exit 1
fi

selected=""
for candidate in "${wallpapers[@]}"; do
  if [[ -f "$candidate" ]]; then
    selected="$candidate"
    break
  fi
done

if [[ -z "$selected" ]]; then
  echo "error: no wallpaper files found in: $wallpaper_dir" >&2
  exit 1
fi

swww img -t random --transition-fps 60 "$selected"
