#!/bin/bash
set -euo pipefail

# Editable theme variables
GTK_THEME_NAME="Everforest-Dark"
ICON_THEME_NAME="Adwaita"
CURSOR_THEME_NAME="Adwaita"
CURSOR_SIZE="18"
FONT_NAME="Adwaita Sans 11"
PREFER_DARK="1"

GTK_SETTINGS_DIR_3="$HOME/.config/gtk-3.0"
GTK_SETTINGS_DIR_4="$HOME/.config/gtk-4.0"
GTK_SETTINGS_3="$GTK_SETTINGS_DIR_3/settings.ini"
GTK_SETTINGS_4="$GTK_SETTINGS_DIR_4/settings.ini"

QT5CT_DIR="$HOME/.config/qt5ct"
QT6CT_DIR="$HOME/.config/qt6ct"
QT5CT_COLORS_DIR="$QT5CT_DIR/colors"
QT6CT_COLORS_DIR="$QT6CT_DIR/colors"
QT5CT_SCHEME="$QT5CT_COLORS_DIR/everforest.conf"
QT6CT_SCHEME="$QT6CT_COLORS_DIR/everforest.conf"
QT5CT_CONF="$QT5CT_DIR/qt5ct.conf"
QT6CT_CONF="$QT6CT_DIR/qt6ct.conf"

SYNC_ROOT=0

for arg in "$@"; do
  case "$arg" in
    --sync-root)
      SYNC_ROOT=1
      ;;
    *)
      ;;
  esac
done

warn() {
  echo "warn: $*"
}

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

write_gtk_settings() {
  local target="$1"

  mkdir -p "$(dirname "$target")"
  cat > "$target" <<EOF
[Settings]
gtk-theme-name=${GTK_THEME_NAME}
gtk-icon-theme-name=${ICON_THEME_NAME}
gtk-font-name=${FONT_NAME}
gtk-cursor-theme-name=${CURSOR_THEME_NAME}
gtk-cursor-theme-size=${CURSOR_SIZE}
gtk-application-prefer-dark-theme=${PREFER_DARK}
EOF
}

write_gtk_settings "$GTK_SETTINGS_3"
write_gtk_settings "$GTK_SETTINGS_4"

if [[ "$SYNC_ROOT" -eq 1 ]]; then
  sync_root_gtk_dirs
fi

THEME_ROOTS=(
  "$HOME/.themes"
  "$HOME/.local/share/themes"
  "/usr/share/themes"
)

THEME_DIR=""
FALLBACK_GTK3=""
FALLBACK_ANY=""

for root in "${THEME_ROOTS[@]}"; do
  candidate="$root/$GTK_THEME_NAME"
  if [[ -d "$candidate" ]]; then
    if [[ -d "$candidate/gtk-3.0" && -d "$candidate/gtk-4.0" ]]; then
      THEME_DIR="$candidate"
      break
    fi
    if [[ -z "$FALLBACK_GTK3" && -d "$candidate/gtk-3.0" ]]; then
      FALLBACK_GTK3="$candidate"
    fi
    if [[ -z "$FALLBACK_ANY" ]]; then
      FALLBACK_ANY="$candidate"
    fi
  fi
done

if [[ -z "$THEME_DIR" ]]; then
  if [[ -n "$FALLBACK_GTK3" ]]; then
    THEME_DIR="$FALLBACK_GTK3"
  elif [[ -n "$FALLBACK_ANY" ]]; then
    THEME_DIR="$FALLBACK_ANY"
  fi
fi

if [[ -n "$THEME_DIR" && -d "$THEME_DIR/gtk-4.0" ]]; then
  mkdir -p "$GTK_SETTINGS_DIR_4"
  if compgen -G "$THEME_DIR/gtk-4.0/*" > /dev/null; then
    ln -nfs "$THEME_DIR/gtk-4.0/"* "$GTK_SETTINGS_DIR_4/"
  fi
else
  if [[ -z "$THEME_DIR" ]]; then
    warn "GTK theme \"$GTK_THEME_NAME\" not found in theme roots."
  else
    warn "$THEME_DIR/gtk-4.0 not found; skipping GTK4 link."
  fi
fi

if command -v gsettings >/dev/null 2>&1; then
  gsettings_failed=0
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

write_qtct_scheme() {
  local target="$1"

  mkdir -p "$(dirname "$target")"
  cat > "$target" <<'EOF'
[ColorScheme]
active_colors=#ffd3c6aa, #ff2e383c, #ff414b50, #ff374145, #ff272e33, #ff2e383c, #ffd3c6aa, #ffd3c6aa, #ffd3c6aa, #ff272e33, #ff1e2326, #ff1e2326, #ff7fbbb3, #ffd3c6aa, #ff83c092, #ffd699b6, #ff374145, #ff2e383c, #ffd3c6aa, #ff859289, #80d3c6aa
inactive_colors=#ff859289, #ff2e383c, #ff414b50, #ff374145, #ff272e33, #ff2e383c, #ff859289, #ff859289, #ff859289, #ff272e33, #ff1e2326, #ff1e2326, #ff7a8478, #ff859289, #ff83c092, #ffd699b6, #ff374145, #ff2e383c, #ff859289, #ff9da9a0, #80859289
disabled_colors=#ff7a8478, #ff2e383c, #ff374145, #ff2e383c, #ff272e33, #ff2e383c, #ff7a8478, #ff7a8478, #ff7a8478, #ff272e33, #ff1e2326, #ff1e2326, #ff2e383c, #ff7a8478, #ff7a8478, #ff7a8478, #ff2e383c, #ff2e383c, #ff7a8478, #ff9da9a0, #807a8478
EOF
}

update_qtct_conf() {
  local target="$1"
  local standard_dialogs="$2"
  local scheme_path="$3"
  local tmp

  tmp="$(mktemp)"

  if [[ -f "$target" ]]; then
    awk -v scheme_path="$scheme_path" -v standard_dialogs="$standard_dialogs" '
      BEGIN { in_app=0; wrote=0 }
      function write_app() {
        print "color_scheme_path=" scheme_path
        print "custom_palette=true"
        print "style=Fusion"
        print "standard_dialogs=" standard_dialogs
      }
      /^\[Appearance\]$/ {
        in_app=1
        print
        next
      }
      /^\[.*\]$/ {
        if (in_app==1 && wrote==0) {
          write_app(); wrote=1
        }
        in_app=0
        print
        next
      }
      {
        if (in_app==1) {
          if ($0 ~ /^(color_scheme_path|custom_palette|style|standard_dialogs)=/) next
        }
        print
      }
      END {
        if (in_app==1 && wrote==0) {
          write_app()
        }
        if (in_app==0 && wrote==0) {
          print ""
          print "[Appearance]"
          write_app()
        }
      }
    ' "$target" > "$tmp"
  else
    cat > "$tmp" <<EOF
[Appearance]
color_scheme_path=$scheme_path
custom_palette=true
style=Fusion
standard_dialogs=$standard_dialogs
EOF
  fi

  mkdir -p "$(dirname "$target")"
  mv "$tmp" "$target"
}

if [[ "${QT_QPA_PLATFORMTHEME:-}" != "qt5ct" && "${QT_QPA_PLATFORMTHEME:-}" != "qt6ct" ]]; then
  warn "QT_QPA_PLATFORMTHEME is not set to qt5ct (qt6ct also works); Qt theming may not apply."
fi

qt5ct_available=1
qt6ct_available=1

if ! command -v qt5ct >/dev/null 2>&1; then
  warn "qt5ct not found; skipping Qt5 config."
  qt5ct_available=0
fi

if ! command -v qt6ct >/dev/null 2>&1; then
  warn "qt6ct not found; skipping Qt6 config."
  qt6ct_available=0
fi

if [[ "$qt5ct_available" -eq 1 ]]; then
  write_qtct_scheme "$QT5CT_SCHEME"
  update_qtct_conf "$QT5CT_CONF" "default" "$QT5CT_SCHEME"
fi

if [[ "$qt6ct_available" -eq 1 ]]; then
  write_qtct_scheme "$QT6CT_SCHEME"
  update_qtct_conf "$QT6CT_CONF" "xdgdesktopportal" "$QT6CT_SCHEME"
fi
