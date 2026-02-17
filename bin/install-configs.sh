#!/bin/bash

set -euo pipefail
shopt -s nullglob

usage() {
  echo "Usage: $0 <source-dir> [package ...] [--all] [--list]"
  echo
  echo "Install config packages from <source-dir>."
  echo
  echo "Arguments:"
  echo "  <source-dir>    Required source directory"
  echo "  package         Optional package name to install"
  echo
  echo "Options:"
  echo "  --all           Install all available packages"
  echo "  --list          List available packages and exit"
  echo "  -h, --help      Show this help message"
  echo
  echo "Behavior:"
  echo "  - If package names are provided, only those packages are installed."
  echo "  - If --all is provided, all packages are installed."
  echo "  - If --list is provided, packages are listed and no install is performed."
  echo "  - If neither package names nor --all are provided, nothing is installed."
  echo "  - If the themes or zed package is installed, the active theme is reapplied."
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  exit 0
fi

if [[ ! -d "$1" ]]; then
  echo "Source directory not found: $1"
  exit 1
fi

SOURCE_DIR=$(realpath "$1")
shift

INSTALL_ALL=0
LIST_ONLY=0
REQUESTED_PACKAGES=()

for arg in "$@"; do
  case "$arg" in
  --all)
    INSTALL_ALL=1
    ;;
  --list)
    LIST_ONLY=1
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  -*)
    echo "Unknown option: $arg"
    usage
    exit 1
    ;;
  *)
    REQUESTED_PACKAGES+=("$arg")
    ;;
  esac
done

if [[ ${#REQUESTED_PACKAGES[@]} -gt 0 ]]; then
  declare -A requested_seen=()
  unique_requested_packages=()

  for package in "${REQUESTED_PACKAGES[@]}"; do
    if [[ -z "${requested_seen[$package]+x}" ]]; then
      unique_requested_packages+=("$package")
      requested_seen["$package"]=1
    fi
  done

  REQUESTED_PACKAGES=("${unique_requested_packages[@]}")
fi

TARGET_DIR="$HOME/.config"
mkdir -p "$TARGET_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLY_THEME_SCRIPT="$SCRIPT_DIR/apply-theme.sh"

join_by_comma() {
  local IFS=", "
  echo "$*"
}

resolve_theme_to_apply() {
  local fallback_theme="everforest"
  local data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
  local current_theme_file="$data_home/current-theme"
  local theme_name=""

  if [[ -r "$current_theme_file" ]]; then
    IFS= read -r theme_name <"$current_theme_file" || true
    theme_name="${theme_name%$'\r'}"
  fi

  if [[ -z "$theme_name" ]]; then
    echo "Warning: unable to read current theme from $current_theme_file; falling back to $fallback_theme" >&2
  fi

  if [[ -n "$theme_name" && -d "$data_home/themes/$theme_name" ]]; then
    printf '%s\n' "$theme_name"
    return
  fi

  if [[ -n "$theme_name" ]]; then
    echo "Warning: active theme '$theme_name' not found in $data_home/themes; falling back to $fallback_theme" >&2
  fi

  if [[ -d "$data_home/themes/$fallback_theme" ]]; then
    printf '%s\n' "$fallback_theme"
    return
  fi

  echo "Warning: no installed themes found in $data_home/themes; skipping theme reapply" >&2
  printf '\n'
}

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

install_package() {
  local package_name="$1"
  local folder="$SOURCE_DIR/$package_name"

  if [[ "$package_name" == "sddm" ]]; then
    local sddm_source="$folder/sddm.conf"
    local sddm_target="/etc/sddm.conf"

    if [[ -f "$sddm_source" ]]; then
      echo "Installing sddm.conf -> $sddm_target"
      install_file "$sddm_source" "$sddm_target" "true"
    else
      echo "Skipping SDDM (missing $sddm_source)"
    fi
    return 0
  fi

  if [[ "$package_name" == "themes" ]]; then
    local themes_target="$HOME/.local/share/themes"
    echo "Installing themes -> $themes_target"
    mkdir -p "$HOME/.local/share"
    install_dir "$folder" "$themes_target" "false"
    return 0
  fi

  local target_path="$TARGET_DIR/$package_name"
  echo "Installing $package_name -> $target_path"
  install_dir "$folder" "$target_path" "false"
}

AVAILABLE_PACKAGES=()
declare -A available_lookup=()

for folder in "$SOURCE_DIR"/*/; do
  folder="${folder%/}"
  folder_name=$(basename "$folder")

  AVAILABLE_PACKAGES+=("$folder_name")
  available_lookup["$folder_name"]=1
done

INSTALL_PACKAGES=()

if [[ "$LIST_ONLY" -eq 1 ]]; then
  if [[ "$INSTALL_ALL" -eq 1 || ${#REQUESTED_PACKAGES[@]} -gt 0 ]]; then
    echo "Ignoring install arguments because --list was provided"
  fi

  for package in "${AVAILABLE_PACKAGES[@]}"; do
    echo "$package"
  done
  exit 0
fi

if [[ "$INSTALL_ALL" -eq 1 ]]; then
  INSTALL_PACKAGES=("${AVAILABLE_PACKAGES[@]}")
elif [[ ${#REQUESTED_PACKAGES[@]} -gt 0 ]]; then
  UNKNOWN_PACKAGES=()

  for package in "${REQUESTED_PACKAGES[@]}"; do
    if [[ -z "${available_lookup[$package]+x}" ]]; then
      UNKNOWN_PACKAGES+=("$package")
    fi
  done

  if [[ ${#UNKNOWN_PACKAGES[@]} -gt 0 ]]; then
    echo "Unknown package name(s): $(join_by_comma "${UNKNOWN_PACKAGES[@]}")"
    if [[ ${#AVAILABLE_PACKAGES[@]} -gt 0 ]]; then
      echo "Valid packages: $(join_by_comma "${AVAILABLE_PACKAGES[@]}")"
    else
      echo "Valid packages: (none found in source directory)"
    fi
    exit 1
  fi

  INSTALL_PACKAGES=("${REQUESTED_PACKAGES[@]}")
fi

echo "Installing configs from: $SOURCE_DIR"
echo "------------------------------------------"

if [[ "$INSTALL_ALL" -eq 1 ]]; then
  echo "Installing all packages"
  if [[ ${#REQUESTED_PACKAGES[@]} -gt 0 ]]; then
    echo "Ignoring explicit package list because --all was provided: $(join_by_comma "${REQUESTED_PACKAGES[@]}")"
  fi
elif [[ ${#INSTALL_PACKAGES[@]} -gt 0 ]]; then
  echo "Installing selected packages: $(join_by_comma "${INSTALL_PACKAGES[@]}")"
else
  echo "No packages selected; nothing to install"
  exit 0
fi

echo "------------------------------------------"

THEMES_INSTALLED=0
ZED_INSTALLED=0

for package in "${INSTALL_PACKAGES[@]}"; do
  install_package "$package"

  if [[ "$package" == "themes" ]]; then
    THEMES_INSTALLED=1
  fi

  if [[ "$package" == "zed" ]]; then
    ZED_INSTALLED=1
  fi
done

echo "------------------------------------------"

if [[ "$THEMES_INSTALLED" -eq 1 || "$ZED_INSTALLED" -eq 1 ]]; then
  THEME_TO_APPLY="$(resolve_theme_to_apply)"

  if [[ -z "$THEME_TO_APPLY" ]]; then
    echo "Skipping active theme reapply"
  else
    echo "Reapplying active theme: $THEME_TO_APPLY"

    if [[ ! -x "$APPLY_THEME_SCRIPT" ]]; then
      echo "Error: apply-theme.sh not found or not executable: $APPLY_THEME_SCRIPT"
      exit 1
    fi

    "$APPLY_THEME_SCRIPT" "$THEME_TO_APPLY"
    echo "------------------------------------------"
  fi
fi

echo "Done!"
