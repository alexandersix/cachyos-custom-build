#!/bin/bash
set -euo pipefail

usage() {
  echo "usage: $(basename "$0") <theme-name> [--sync-root]" >&2
}

warn() {
  echo "warn: $*"
}

step() {
  echo "==> $*"
}

run_step() {
  local label="$1"
  local fn="$2"

  step "Applying $label"
  "$fn"
  step "Applied $label"
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

resolve_user_home() {
  local user="$1"
  local home=""

  if [[ -n "$user" ]] && command -v getent >/dev/null 2>&1; then
    home="$(getent passwd "$user" | cut -d: -f6)"
  fi

  if [[ -z "$home" && -n "$user" ]]; then
    home="$(eval echo "~$user")"
  fi

  if [[ -z "$home" ]]; then
    home="${HOME:-}"
  fi

  echo "$home"
}

SCRIPT_PATH="$(resolve_path "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TARGET_USER="${SUDO_USER:-${USER:-}}"
USER_HOME="${HOME:-}"
if [[ -z "$USER_HOME" && -n "$TARGET_USER" ]]; then
  USER_HOME="$(resolve_user_home "$TARGET_USER")"
fi

if [[ "${EUID}" -eq 0 && -n "${SUDO_USER:-}" ]]; then
  USER_HOME="$(resolve_user_home "$SUDO_USER")"
fi

if [[ -z "$USER_HOME" ]]; then
  echo "error: unable to resolve user home directory" >&2
  exit 1
fi

CONFIG_HOME="${XDG_CONFIG_HOME:-$USER_HOME/.config}"
DATA_HOME="${XDG_DATA_HOME:-$USER_HOME/.local/share}"
THEME_ROOT="$DATA_HOME/themes/$THEME_NAME"

CURRENT_THEME_FILE="$DATA_HOME/current-theme"

if [[ ! -d "$THEME_ROOT" ]]; then
  echo "error: theme not found: $THEME_ROOT" >&2
  exit 1
fi

if [[ ! -f "$THEME_ROOT/nvim/theme.lua" ]]; then
  warn "missing Neovim manifest: $THEME_ROOT/nvim/theme.lua (Neovim will fall back to habamax)"
fi

mkdir -p "$DATA_HOME"
printf '%s\n' "$THEME_NAME" >"$CURRENT_THEME_FILE"

GTK_SETTINGS_DIR_3="$CONFIG_HOME/gtk-3.0"
GTK_SETTINGS_DIR_4="$CONFIG_HOME/gtk-4.0"
GTK_SETTINGS_3="$GTK_SETTINGS_DIR_3/settings.ini"
GTK_SETTINGS_4="$GTK_SETTINGS_DIR_4/settings.ini"

QT5CT_DIR="$CONFIG_HOME/qt5ct"
QT6CT_DIR="$CONFIG_HOME/qt6ct"
QT5CT_COLORS_DIR="$QT5CT_DIR/colors"
QT6CT_COLORS_DIR="$QT6CT_DIR/colors"
QT5CT_CONF="$QT5CT_DIR/qt5ct.conf"
QT6CT_CONF="$QT6CT_DIR/qt6ct.conf"

QUTEBROWSER_CONFIG_DIR="$CONFIG_HOME/qutebrowser"
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

link_gtk4_assets() {
  local theme_roots=(
    "$USER_HOME/.themes"
    "$DATA_HOME/themes"
    "/usr/share/themes"
  )
  local theme_dir=""
  local root
  local candidate

  if [[ -z "$GTK_THEME_NAME" ]]; then
    warn "GTK theme name missing; skipping GTK4 asset links."
    return
  fi

  for root in "${theme_roots[@]}"; do
    candidate="$root/$GTK_THEME_NAME"
    if [[ -d "$candidate/gtk-4.0" ]]; then
      theme_dir="$candidate"
      break
    fi
  done

  if [[ -z "$theme_dir" ]]; then
    warn "GTK4 theme assets not found for $GTK_THEME_NAME; skipping GTK4 links."
    return
  fi

  mkdir -p "$GTK_SETTINGS_DIR_4"
  if compgen -G "$theme_dir/gtk-4.0/*" >/dev/null; then
    ln -nfs "$theme_dir/gtk-4.0/"* "$GTK_SETTINGS_DIR_4/"
  else
    warn "No GTK4 assets found in $theme_dir/gtk-4.0."
  fi
}

gtk_theme_exists() {
  local theme_name="$1"
  local theme_roots=(
    "$USER_HOME/.themes"
    "$DATA_HOME/themes"
    "/usr/share/themes"
  )
  local root

  if [[ -z "$theme_name" ]]; then
    return 1
  fi

  for root in "${theme_roots[@]}"; do
    if [[ -d "$root/$theme_name" ]]; then
      return 0
    fi
  done

  return 1
}

ensure_gtk_theme_available() {
  local fallback_theme="Adwaita-dark"

  if gtk_theme_exists "$GTK_THEME_NAME"; then
    return
  fi

  if ! gtk_theme_exists "$fallback_theme"; then
    fallback_theme="Adwaita"
  fi

  warn "GTK theme '$GTK_THEME_NAME' not found; falling back to $fallback_theme to keep dark mode."
  GTK_THEME_NAME="$fallback_theme"

  sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$GTK_THEME_NAME/" "$GTK_SETTINGS_3" "$GTK_SETTINGS_4"
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

  read_gtk_settings "$GTK_SETTINGS_3"
  ensure_gtk_theme_available
  link_gtk4_assets
  apply_gsettings
  echo "note: GTK4 apps (e.g., Nautilus) may require a full restart: killall nautilus"
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

apply_wallpaper() {
  local wallpaper_dir="$THEME_ROOT/wallpapers"

  if [[ -d "$wallpaper_dir" ]]; then
    if ! "$SCRIPT_DIR/wallpaper.sh" "$wallpaper_dir"; then
      warn "failed to apply wallpaper from: $wallpaper_dir"
    fi
  else
    warn "missing wallpapers directory: $wallpaper_dir"
  fi
}

apply_sddm() {
  local sddm_theme_name="silent"
  local sddm_theme_dir="/usr/share/sddm/themes/$sddm_theme_name"
  local sddm_metadata="$sddm_theme_dir/metadata.desktop"
  local sddm_override_src="$THEME_ROOT/sddm/$sddm_theme_name/configs/background.conf.user"
  local sddm_wallpaper_src=""
  local sddm_wallpaper_name=""
  local sddm_wallpaper_dest=""
  local sddm_config_file="theme.conf"
  local sddm_config_user=""
  local wallpaper_dir="$THEME_ROOT/wallpapers"
  local wallpaper_candidates=()
  local tmp_override=""

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

  if [[ ! -d "$wallpaper_dir" ]]; then
    warn "missing wallpapers directory: $wallpaper_dir"
    return
  fi

  local shopt_state
  shopt_state="$(shopt -p nullglob nocaseglob)"
  shopt -s nullglob nocaseglob
  wallpaper_candidates=("$wallpaper_dir"/*.{png,jpg,jpeg,webp,gif,bmp})
  eval "$shopt_state"

  if [[ ${#wallpaper_candidates[@]} -eq 0 ]]; then
    warn "no wallpapers found in: $wallpaper_dir"
    return
  fi

  IFS= read -r sddm_wallpaper_src < <(printf '%s\n' "${wallpaper_candidates[@]}" | LC_ALL=C sort)

  if [[ -z "$sddm_wallpaper_src" ]]; then
    warn "failed to select SDDM wallpaper from: $wallpaper_dir"
    return
  fi

  sddm_wallpaper_name="$(basename "$sddm_wallpaper_src")"
  sddm_wallpaper_dest="$sddm_theme_dir/backgrounds/$sddm_wallpaper_name"

  tmp_override="$(mktemp)"
  while IFS= read -r line; do
    if [[ "$line" =~ ^([[:space:]]*)background[[:space:]]*= ]]; then
      printf '%sbackground = "%s"\n' "${BASH_REMATCH[1]}" "$sddm_wallpaper_name" >>"$tmp_override"
    else
      printf '%s\n' "$line" >>"$tmp_override"
    fi
  done <"$sddm_override_src"

  if [[ "${EUID}" -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then
      if ! sudo mkdir -p "$(dirname "$sddm_config_user")" "$sddm_theme_dir/backgrounds"; then
        warn "failed to create SDDM config directories"
        return
      fi
      if ! sudo cp -f "$tmp_override" "$sddm_config_user"; then
        warn "failed to write SDDM override config"
        return
      fi
      if ! sudo cp -f "$sddm_wallpaper_src" "$sddm_wallpaper_dest"; then
        warn "failed to copy SDDM wallpaper"
        return
      fi
    else
      warn "sudo not found; skipping SDDM updates."
    fi
  else
    mkdir -p "$(dirname "$sddm_config_user")" "$sddm_theme_dir/backgrounds"
    cp -f "$tmp_override" "$sddm_config_user"
    cp -f "$sddm_wallpaper_src" "$sddm_wallpaper_dest"
  fi

  rm -f "$tmp_override"
}

apply_qutebrowser() {
  local qutebrowser_theme_dir="$THEME_ROOT/qutebrowser"
  local qutebrowser_theme_src="$qutebrowser_theme_dir/current.py"

  mkdir -p "$QUTEBROWSER_THEME_DIR"

  if [[ -f "$qutebrowser_theme_src" ]]; then
    cp -f "$qutebrowser_theme_src" "$QUTEBROWSER_THEME_TARGET"
  else
    warn "missing qutebrowser theme file: $qutebrowser_theme_src"
  fi
}

apply_waybar() {
  local theme_file="$THEME_ROOT/waybar/style.css"
  local waybar_dir="$CONFIG_HOME/waybar"
  local waybar_style="$waybar_dir/style.css"

  if [[ -f "$theme_file" ]]; then
    mkdir -p "$waybar_dir"
    cp -f "$theme_file" "$waybar_style"

    if [[ -x "$SCRIPT_DIR/rebar.sh" ]]; then
      if ! "$SCRIPT_DIR/rebar.sh" >/dev/null 2>&1; then
        warn "failed to restart waybar; run $SCRIPT_DIR/rebar.sh manually"
      fi
    else
      warn "rebar script not found or not executable: $SCRIPT_DIR/rebar.sh"
    fi
  else
    warn "missing waybar theme"
  fi
}

apply_ghostty() {
  local theme_file="$THEME_ROOT/ghostty/theme"
  local ghostty_dir="$CONFIG_HOME/ghostty"
  local ghostty_theme="$ghostty_dir/theme"

  if [[ -f "$theme_file" ]]; then
    mkdir -p "$ghostty_dir"
    cp -f "$theme_file" "$ghostty_theme"

    if pgrep -x ghostty >/dev/null 2>&1; then
      if ! pkill -USR2 ghostty >/dev/null 2>&1; then
        warn "failed to signal ghostty for theme reload"
      fi
    fi
  else
    warn "missing ghostty theme"
  fi
}

apply_rofi() {
  local theme_file="$THEME_ROOT/rofi/theme.rasi"
  local rofi_dir="$CONFIG_HOME/rofi"
  local rofi_theme="$rofi_dir/theme.rasi"

  if [[ -f "$theme_file" ]]; then
    mkdir -p "$rofi_dir"
    cp -f "$theme_file" "$rofi_theme"
  else
    warn "missing rofi theme"
  fi
}

apply_wlogout() {
  local theme_file="$THEME_ROOT/wlogout/style.css"
  local icons_directory="$THEME_ROOT/wlogout/icons"
  local wlogout_dir="$CONFIG_HOME/wlogout"
  local wlogout_style="$wlogout_dir/style.css"
  local wlogout_icons="$wlogout_dir/icons"

  mkdir -p "$wlogout_dir"

  if [[ -f "$theme_file" ]]; then
    cp -f "$theme_file" "$wlogout_style"
  else
    warn "missing wlogout theme"
  fi

  if [[ -d "$icons_directory" ]]; then
    rm -rf "$wlogout_icons"
    cp -Rf "$icons_directory" "$wlogout_icons"
  else
    warn "missing wlogout icons"
  fi
}

apply_tmux() {
  local theme_file="$THEME_ROOT/tmux/theme.conf"
  local tmux_dir="$CONFIG_HOME/tmux"
  local tmux_theme="$tmux_dir/theme.conf"
  local tmux_conf="$tmux_dir/tmux.conf"
  local tpm_clean="$USER_HOME/.tmux/plugins/tpm/bin/clean_plugins"
  local tpm_install="$USER_HOME/.tmux/plugins/tpm/bin/install_plugins"

  if [[ -f "$theme_file" ]]; then
    mkdir -p "$tmux_dir"
    cp -f "$theme_file" "$tmux_theme"

    if [[ -x "$tpm_clean" ]]; then
      if ! "$tpm_clean" >/dev/null 2>&1; then
        warn "tmux plugin cleanup failed"
      fi
    fi

    if [[ -x "$tpm_install" ]]; then
      if ! "$tpm_install" >/dev/null 2>&1; then
        warn "tmux plugin install failed"
      fi
    fi

    if command -v tmux >/dev/null 2>&1 && tmux list-sessions >/dev/null 2>&1; then
      if ! tmux source-file "$tmux_conf" >/dev/null 2>&1; then
        warn "failed to reload tmux config"
      fi
    fi
  else
    warn "missing tmux theme"
  fi
}

run_step "qutebrowser" apply_qutebrowser
run_step "gtk" apply_gtk
run_step "qt" apply_qt
run_step "wallpaper" apply_wallpaper
run_step "waybar" apply_waybar
run_step "ghostty" apply_ghostty
run_step "rofi" apply_rofi
run_step "wlogout" apply_wlogout
run_step "tmux" apply_tmux
run_step "sddm" apply_sddm
