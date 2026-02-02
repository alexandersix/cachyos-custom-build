# GTK/Qt Theming Guide

This guide documents how to create and apply GTK/Qt themes in this repo, including what files to edit, which commands to run, and common pitfalls.

## Files that define the theme

### Theme script (single source of truth)
- `bin/apply-gtk-qt-everforest.sh`
  - GTK variables at the top:
    - `GTK_THEME_NAME`, `ICON_THEME_NAME`, `CURSOR_THEME_NAME`, `CURSOR_SIZE`, `FONT_NAME`, `PREFER_DARK`
  - Qt palette generation in `write_qtct_scheme()`
  - Qt config updates in `update_qtct_conf()`

### Qt configs (written by the script)
- `~/.config/qt6ct/qt6ct.conf`
- `~/.config/qt6ct/colors/everforest.conf`
- `~/.config/qt5ct/qt5ct.conf`
- `~/.config/qt5ct/colors/everforest.conf`

### GTK configs (written by the script)
- `~/.config/gtk-3.0/settings.ini`
- `~/.config/gtk-4.0/settings.ini`

### Session environment (required for Qt theming)
- `./.pam_environment` (symlinked to `~/.pam_environment` by `bin/symlink.sh`)
  - Uses PAM syntax: `VAR DEFAULT=value`
  - Ensures `QT_QPA_PLATFORMTHEME=qt6ct` and `QT_QUICK_CONTROLS_STYLE=Fusion` are set at login

### Tmux environment (so Qt vars exist inside tmux)
- `tmux/tmux.conf`
  - `update-environment` includes Qt/Wayland vars so tmux pulls them in on attach

## How to create a new GTK/Qt theme

### 1) Update GTK variables in the script
Edit `bin/apply-gtk-qt-everforest.sh` at the top:
- `GTK_THEME_NAME`: GTK theme directory name (e.g., `Everforest-Dark`)
- `ICON_THEME_NAME`: icon theme name (e.g., `Adwaita`)
- `CURSOR_THEME_NAME`: cursor theme name (e.g., `Adwaita`)
- `CURSOR_SIZE`: integer size (e.g., `18`)
- `FONT_NAME`: GTK font string (e.g., `Adwaita Sans 11`)
- `PREFER_DARK`: `1` for dark, `0` for light

### 2) Update the Qt palette in `write_qtct_scheme()`
Edit the palette block in `bin/apply-gtk-qt-everforest.sh`:
- Keep **21 entries** for each of:
  - `active_colors`
  - `inactive_colors`
  - `disabled_colors`
- Use **#AARRGGBB** format for each color.
- These files are written to:
  - `~/.config/qt6ct/colors/everforest.conf`
  - `~/.config/qt5ct/colors/everforest.conf`

## Commands to apply a theme

### 1) Run the script
```bash
~/Code/six-os/bin/apply-gtk-qt-everforest.sh
```

### 2) Optional: sync root GTK configs (only if you run GUI apps as root)
```bash
~/Code/six-os/bin/apply-gtk-qt-everforest.sh --sync-root
```

### 3) Restart apps to pick up changes
- Close and reopen GTK and Qt apps (no hot reload).
- Optional service restarts:
```bash
pkill waybar && waybar
systemctl --user restart swaync.service
```

## Verification checklist

- Verify session vars (outside tmux):
  - `printenv QT_QPA_PLATFORMTHEME`
- Verify inside tmux (if used):
  - `printenv QT_QPA_PLATFORMTHEME`
- GTK3 app: `nwg-look`
- GTK4 app: `gnome-text-editor` or `loupe`
- Qt5 app: `qt5ct`
- Qt6 app: `qt6ct`

## Recommendations and pitfalls

- Qt palettes must have **21 entries** per line and **#AARRGGBB** format.
- Qt palettes must live under:
  - `~/.config/qt6ct/colors/`
  - `~/.config/qt5ct/colors/`
- Ensure `QT_QPA_PLATFORMTHEME=qt6ct` is set at login:
  - `./.pam_environment` → `~/.pam_environment`
- If Qt looks correct outside tmux but not inside:
  - Confirm `tmux/tmux.conf` includes the Qt vars in `update-environment`.
- GTK4/libadwaita theming relies on the GTK4 symlink step in the script.
- Always re-open apps after applying changes.
