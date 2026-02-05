#!/bin/bash

set -euo pipefail
shopt -s nullglob

usage() {
  echo "Usage: $0 /path/to/source_configs"
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

if [[ ! -d "$1" ]]; then
  echo "Source directory not found: $1"
  exit 1
fi

SOURCE_DIR=$(realpath "$1")

TARGET_DIR="$HOME/.config"
mkdir -p "$TARGET_DIR"

run() {
  local use_sudo="$1"
  shift

  if [[ "$use_sudo" == "true" ]]; then
    sudo "$@"
  else
    "$@"
  fi
}

backup_existing() {
  local target="$1"
  local use_sudo="$2"

  if [[ ! -e "$target" && ! -L "$target" ]]; then
    return 0
  fi

  local backup_dir="${target}.bak"
  run "$use_sudo" rm -rf "$backup_dir"

  if [[ -d "$target" ]]; then
    if [[ -L "$target" ]]; then
      run "$use_sudo" cp -aL "$target" "$backup_dir"
    else
      run "$use_sudo" cp -a "$target" "$backup_dir"
    fi
  else
    run "$use_sudo" mkdir -p "$backup_dir"
    local base
    base=$(basename "$target")
    local dest="$backup_dir/$base"

    if [[ -L "$target" && -e "$target" ]]; then
      run "$use_sudo" cp -aL "$target" "$dest"
    else
      run "$use_sudo" cp -a "$target" "$dest"
    fi
  fi

  run "$use_sudo" rm -rf "$target"
}

install_dir() {
  local source="$1"
  local target="$2"
  local use_sudo="$3"

  source="${source%/}"
  if [[ ! -d "$source" ]]; then
    echo "Skipping missing directory: $source"
    return 0
  fi

  backup_existing "$target" "$use_sudo"
  run "$use_sudo" mkdir -p "$(dirname "$target")"
  run "$use_sudo" cp -a "$source" "$target"
}

install_file() {
  local source="$1"
  local target="$2"
  local use_sudo="$3"

  if [[ ! -f "$source" && ! -L "$source" ]]; then
    echo "Skipping missing file: $source"
    return 0
  fi

  backup_existing "$target" "$use_sudo"
  run "$use_sudo" mkdir -p "$(dirname "$target")"
  run "$use_sudo" cp -f "$source" "$target"
}

echo "Installing configs from: $SOURCE_DIR"
echo "------------------------------------------"

for folder in "$SOURCE_DIR"/*/; do
  folder="${folder%/}"
  folder_name=$(basename "$folder")

  if [[ "$folder_name" == "sddm" ]]; then
    sddm_source="$folder/sddm.conf"
    sddm_target="/etc/sddm.conf"

    if [[ -f "$sddm_source" ]]; then
      echo "Installing sddm.conf -> $sddm_target"
      install_file "$sddm_source" "$sddm_target" "true"
    else
      echo "Skipping SDDM (missing $sddm_source)"
    fi
    continue
  fi

  if [[ "$folder_name" == "themes" ]]; then
    themes_target="$HOME/.local/share/themes"
    echo "Installing themes -> $themes_target"
    mkdir -p "$HOME/.local/share"
    install_dir "$folder" "$themes_target" "false"
    continue
  fi

  target_path="$TARGET_DIR/$folder_name"
  echo "Installing $folder_name -> $target_path"
  install_dir "$folder" "$target_path" "false"
done

echo "------------------------------------------"
echo "Done!"
