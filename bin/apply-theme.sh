#!/bin/bash
set -euo pipefail

usage() {
  echo "usage: $(basename "$0") <theme-name> [--sync-root]" >&2
}

warn() {
  echo "warn: $*"
}

THEME_NAME=""
SYNC_ROOT=0

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
    if [[ -z "$THEME_NAME" ]]; then
      THEME_NAME="$arg"
    else
      echo "error: unexpected argument: $arg" >&2
      usage
      exit 1
    fi
    ;;
  esac
done

if [[ -z "$THEME_NAME" ]]; then
  usage
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
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
THEME_ROOT="$REPO_ROOT/themes/$THEME_NAME"

if [[ ! -d "$THEME_ROOT" ]]; then
  echo "error: theme not found: $THEME_ROOT" >&2
  exit 1
fi

GTK_SETTINGS_DIR_3="$HOME/.config/gtk-3.0"
GTK_SETTINGS_DIR_4="$HOME/.config/gtk-4.0"
GTK_SETTINGS_3="$GTK_SETTINGS_DIR_3/settings.ini"
GTK_SETTINGS_4="$GTK_SETTINGS_DIR_4/settings.ini"

QT5CT_DIR="$HOME/.config/qt5ct"
QT6CT_DIR="$HOME/.config/qt6ct"
QT5CT_COLORS_DIR="$QT5CT_DIR/colors"
QT6CT_COLORS_DIR="$QT6CT_DIR/colors"
QT5CT_CONF="$QT5CT_DIR/qt5ct.conf"
QT6CT_CONF="$QT6CT_DIR/qt6ct.conf"

QUTEBROWSER_CONFIG_DIR="$REPO_ROOT/qutebrowser"
QUTEBROWSER_THEME_DIR="$QUTEBROWSER_CONFIG_DIR/themes"
QUTEBROWSER_THEME_TARGET="$QUTEBROWSER_THEME_DIR/current.py"

sync_root_gtk_dirs() {
  local root_config="/root/.config"

  if [[ "${EUID}" -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then
      sudo mkdir -p "$root_config"
      sudo ln -sfT "$GTK_SETTINGS_DIR_3" "$root_config/gtk-3.0"
      sudo ln -sfT "$GTK_SETTINGS_DIR_4" "$root_config/gtk-4.0"
    else
      echo "error: root privileges required for --sync-root" >&2
      exit 1
    fi
  else
    mkdir -p "$root_config"
    ln -sfT "$GTK_SETTINGS_DIR_3" "$root_config/gtk-3.0"
    ln -sfT "$GTK_SETTINGS_DIR_4" "$root_config/gtk-4.0"
  fi
}

GTK_THEME_NAME=""
ICON_THEME_NAME=""
CURSOR_THEME_NAME=""
CURSOR_SIZE=""
FONT_NAME=""
PREFER_DARK=""

read_gtk_settings() {
  local source="$1"
  local line
  local key
  local value

  GTK_THEME_NAME=""
  ICON_THEME_NAME=""
  CURSOR_THEME_NAME=""
  CURSOR_SIZE=""
  FONT_NAME=""
  PREFER_DARK=""

  while IFS= read -r line; do
    case "$line" in
    "" | \#* | \;* | \[*)
      continue
      ;;
    esac

    key="${line%%=*}"
    value="${line#*=}"

    case "$key" in
    gtk-theme-name)
      GTK_THEME_NAME="$value"
      ;;
    gtk-icon-theme-name)
      ICON_THEME_NAME="$value"
      ;;
    gtk-font-name)
      FONT_NAME="$value"
      ;;
    gtk-cursor-theme-name)
      CURSOR_THEME_NAME="$value"
      ;;
    gtk-cursor-theme-size)
      CURSOR_SIZE="$value"
      ;;
    gtk-application-prefer-dark-theme)
      PREFER_DARK="$value"
      ;;
    esac
  done <"$source"
}

apply_gsettings() {
  if [[ -z "$GTK_THEME_NAME" || -z "$ICON_THEME_NAME" || -z "$FONT_NAME" || -z "$CURSOR_THEME_NAME" || -z "$CURSOR_SIZE" || -z "$PREFER_DARK" ]]; then
    warn "Missing GTK settings in theme; skipping gsettings updates."
    return
  fi

  if command -v gsettings >/dev/null 2>&1; then
    local gsettings_failed=0

    gsettings_set() {
      local schema="$1"
      local key="$2"
      local value="$3"

      if ! gsettings set "$schema" "$key" "$value" 2>/dev/null; then
        gsettings_failed=1
      fi
    }

    gsettings_set org.gnome.desktop.interface gtk-theme "$GTK_THEME_NAME"
    gsettings_set org.gnome.desktop.interface icon-theme "$ICON_THEME_NAME"
    gsettings_set org.gnome.desktop.interface font-name "$FONT_NAME"
    gsettings_set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME_NAME"
    gsettings_set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE"
    if [[ "$PREFER_DARK" == "1" ]]; then
      gsettings_set org.gnome.desktop.interface color-scheme "prefer-dark"
    else
      gsettings_set org.gnome.desktop.interface color-scheme "default"
    fi

    if [[ "$gsettings_failed" -ne 0 ]]; then
      warn "Failed to apply gsettings; ensure a user session is available."
    fi
  else
    warn "gsettings not found; skipping gsettings updates."
  fi
}

apply_gtk() {
  local theme_settings_3="$THEME_ROOT/gtk/gtk-3.0/settings.ini"
  local theme_settings_4="$THEME_ROOT/gtk/gtk-4.0/settings.ini"

  if [[ ! -f "$theme_settings_3" ]]; then
    echo "error: missing $theme_settings_3" >&2
    exit 1
  fi

  if [[ ! -f "$theme_settings_4" ]]; then
    echo "error: missing $theme_settings_4" >&2
    exit 1
  fi

  mkdir -p "$GTK_SETTINGS_DIR_3" "$GTK_SETTINGS_DIR_4"
  cp -f "$theme_settings_3" "$GTK_SETTINGS_3"
  cp -f "$theme_settings_4" "$GTK_SETTINGS_4"

  if [[ "$SYNC_ROOT" -eq 1 ]]; then
    sync_root_gtk_dirs
  fi

  read_gtk_settings "$theme_settings_3"
  apply_gsettings
}

copy_dir_contents() {
  local source_dir="$1"
  local target_dir="$2"

  mkdir -p "$target_dir"
  cp -Rf "$source_dir/." "$target_dir/"
}

apply_qt() {
  local qt5ct_conf_src="$THEME_ROOT/qt/qt5ct/qt5ct.conf"
  local qt6ct_conf_src="$THEME_ROOT/qt/qt6ct/qt6ct.conf"
  local qt5ct_colors_src="$THEME_ROOT/qt/qt5ct/colors"
  local qt6ct_colors_src="$THEME_ROOT/qt/qt6ct/colors"

  if [[ ! -f "$qt5ct_conf_src" ]]; then
    echo "error: missing $qt5ct_conf_src" >&2
    exit 1
  fi

  if [[ ! -f "$qt6ct_conf_src" ]]; then
    echo "error: missing $qt6ct_conf_src" >&2
    exit 1
  fi

  if [[ ! -d "$qt5ct_colors_src" ]]; then
    echo "error: missing $qt5ct_colors_src" >&2
    exit 1
  fi

  if [[ ! -d "$qt6ct_colors_src" ]]; then
    echo "error: missing $qt6ct_colors_src" >&2
    exit 1
  fi

  if [[ "${QT_QPA_PLATFORMTHEME:-}" != "qt5ct" && "${QT_QPA_PLATFORMTHEME:-}" != "qt6ct" ]]; then
    warn "QT_QPA_PLATFORMTHEME is not set to qt5ct (qt6ct also works); Qt theming may not apply."
  fi

  if ! command -v qt5ct >/dev/null 2>&1; then
    warn "qt5ct not found; Qt5 apps may ignore qt5ct config."
  fi

  if ! command -v qt6ct >/dev/null 2>&1; then
    warn "qt6ct not found; Qt6 apps may ignore qt6ct config."
  fi

  mkdir -p "$QT5CT_DIR" "$QT6CT_DIR" "$QT5CT_COLORS_DIR" "$QT6CT_COLORS_DIR"
  cp -f "$qt5ct_conf_src" "$QT5CT_CONF"
  cp -f "$qt6ct_conf_src" "$QT6CT_CONF"
  copy_dir_contents "$qt5ct_colors_src" "$QT5CT_COLORS_DIR"
  copy_dir_contents "$qt6ct_colors_src" "$QT6CT_COLORS_DIR"
}

apply_sddm() {
  local sddm_theme_name="silent"
  local sddm_theme_dir="/usr/share/sddm/themes/$sddm_theme_name"
  local sddm_metadata="$sddm_theme_dir/metadata.desktop"
  local sddm_override_src="$THEME_ROOT/sddm/$sddm_theme_name/configs/background.conf.user"
  local sddm_wallpaper_src="$HOME/wallpapers/everforest/polyscape_2.png"
  local sddm_wallpaper_name="polyscape_2.png"
  local sddm_wallpaper_dest="$sddm_theme_dir/backgrounds/$sddm_wallpaper_name"
  local sddm_config_file="theme.conf"
  local sddm_config_user=""

  if [[ ! -d "$sddm_theme_dir" ]]; then
    warn "SDDM theme not found: $sddm_theme_dir"
    return
  fi

  if [[ ! -f "$sddm_override_src" ]]; then
    warn "missing SDDM override file: $sddm_override_src"
    return
  fi

  if [[ -f "$sddm_metadata" ]]; then
    local line

    while IFS= read -r line; do
      case "$line" in
      "" | \#* | \;*)
        continue
        ;;
      ConfigFile=*)
        sddm_config_file="${line#ConfigFile=}"
        sddm_config_file="${sddm_config_file%%[[:space:]]*}"
        break
        ;;
      esac
    done <"$sddm_metadata"
  fi

  sddm_config_user="$sddm_theme_dir/${sddm_config_file}.user"

  if [[ ! -f "$sddm_wallpaper_src" ]]; then
    warn "missing SDDM wallpaper source: $sddm_wallpaper_src"
    return
  fi

  if [[ "${EUID}" -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then
      sudo mkdir -p "$(dirname "$sddm_config_user")" "$sddm_theme_dir/backgrounds"
      sudo cp -f "$sddm_override_src" "$sddm_config_user"
      sudo cp -f "$sddm_wallpaper_src" "$sddm_wallpaper_dest"
    else
      warn "sudo not found; skipping SDDM updates."
    fi
  else
    mkdir -p "$(dirname "$sddm_config_user")" "$sddm_theme_dir/backgrounds"
    cp -f "$sddm_override_src" "$sddm_config_user"
    cp -f "$sddm_wallpaper_src" "$sddm_wallpaper_dest"
  fi
}

apply_qutebrowser() {
  local qutebrowser_theme_src="$THEME_ROOT/qutebrowser/everforest.py"

  if [[ -f "$qutebrowser_theme_src" ]]; then
    mkdir -p "$QUTEBROWSER_THEME_DIR"
    cp -f "$qutebrowser_theme_src" "$QUTEBROWSER_THEME_TARGET"
  else
    warn "missing qutebrowser theme file: $qutebrowser_theme_src"
  fi
}

apply_waybar() {
  local theme_file="$THEME_ROOT/waybar/style.css"

  if [[ -f "$theme_file" ]]; then
    cp -f "$theme_file" "$HOME/.config/waybar"
    rebar.sh &>/dev/null
  else
    warn "missing waybar theme"
  fi
}

apply_ghostty() {
  local theme_file="$THEME_ROOT/ghostty/theme"

  if [[ -f "$theme_file" ]]; then
    cp -f "$theme_file" "$HOME/.config/ghostty"
    pkill -USR2 ghostty
  else
    warn "missing ghostty theme"
  fi
}

apply_gtk
apply_qt
apply_sddm
apply_qutebrowser
apply_waybar
apply_ghostty
