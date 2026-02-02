# GTK/QT Everforest Theming Plan

Goal: create a single script in `bin/` that applies Everforest theming to GTK and Qt apps, following the settings Dusky uses for GTK/QT, but with an Everforest palette instead of matugen output.

## Scope
- Target GTK 3 and GTK 4.
- Target Qt 5 and Qt 6 using qt5ct/qt6ct.
- Do not introduce matugen yet.
- Assume Arch-based system and Wayland session.

## Inputs and assumptions
- Everforest GTK theme is installed on the system (e.g., `Everforest-Dark`).
- Existing theme assets may live under `~/.themes/` or `~/.local/share/themes/`.
- qt5ct/qt6ct are installed.
- `gsettings` is available for GTK key updates.
- Environment variable `QT_QPA_PLATFORMTHEME=qt6ct` should already be set in the session (warn if missing).

## Script placement and name
- Create `bin/apply-gtk-qt-everforest.sh` (or similar; must live in `bin/`).
- Use `#!/bin/bash` and `set -euo pipefail`.
- Keep output minimal and actionable (only errors/warnings).

## Settings to apply (mirrors Dusky)
### GTK settings
- Write `~/.config/gtk-3.0/settings.ini` with:
  - `gtk-theme-name=<Everforest GTK theme name>`
  - `gtk-icon-theme-name=<icon theme>`
  - `gtk-font-name=<font name and size>`
  - `gtk-cursor-theme-name=<cursor theme>`
  - `gtk-cursor-theme-size=<size>`
  - `gtk-application-prefer-dark-theme=1`
- Write `~/.config/gtk-4.0/settings.ini` with the same core keys (as in Dusky).
- If a GTK4 theme directory exists inside the Everforest theme, link it for libadwaita:
  - `mkdir -p ~/.config/gtk-4.0`
  - `ln -nfs <theme>/gtk-4.0/* ~/.config/gtk-4.0/`
- Apply gsettings:
  - `org.gnome.desktop.interface gtk-theme`
  - `org.gnome.desktop.interface icon-theme`
  - `org.gnome.desktop.interface font-name`
  - `org.gnome.desktop.interface cursor-theme`
  - `org.gnome.desktop.interface cursor-size`
  - `org.gnome.desktop.interface color-scheme prefer-dark`

### Qt settings (qt5ct/qt6ct)
- Create an Everforest color scheme file for qtct.
  - Place it in `~/.config/qt5ct/everforest.conf` and `~/.config/qt6ct/everforest.conf` or a shared location referenced by both.
  - Use the Everforest palette (dark-hard) for colors.
- Update `~/.config/qt5ct/qt5ct.conf` and `~/.config/qt6ct/qt6ct.conf` to enforce:
  - `[Appearance]`
  - `color_scheme_path=<path to everforest.conf>`
  - `custom_palette=true`
  - `style=Fusion`
  - `standard_dialogs=default` for Qt5
  - `standard_dialogs=xdgdesktopportal` for Qt6
- Preserve existing sections like `[Fonts]` and `[Interface]` when updating.

## Script behavior details
- Resolve Everforest GTK theme name by searching common theme roots:
  - `~/.themes`, `~/.local/share/themes`, and `/usr/share/themes`.
  - Prefer a theme that contains `gtk-3.0` and `gtk-4.0` folders if available.
- Read all settings (theme name, icon theme, cursor theme/size, font) from variables near the top of the script for easy edits.
- If required tools are missing (`gsettings`, `qt5ct`, `qt6ct`), warn and continue with the pieces that can apply.
- If `QT_QPA_PLATFORMTHEME` is not `qt6ct`, emit a warning explaining Qt theming may not apply until the session variable is set.
- No backups, no logging files, no destructive operations beyond controlled config updates.

## Optional extension (flagged)
- Add a `--sync-root` flag to mirror Dusky’s root GTK symlink logic:
  - Link `/root/.config/gtk-3.0` and `/root/.config/gtk-4.0` to the user’s directories.
  - Only run this step when explicitly requested.

## Manual verification steps
1. Run the script.
2. Open a GTK3 app (e.g., `nwg-look`) and a GTK4 app to verify theming.
3. Open a Qt app and verify styling and colors.
4. If Qt theming fails, confirm `QT_QPA_PLATFORMTHEME=qt6ct` in the session.

## Chunk plan (small, agent-friendly)
### Defaults (top-of-script variables)
- GTK theme name: `Everforest-Dark`
- Icon theme: `Fluent-teal-dark`
- Cursor theme: `Bibata-Modern-Classic`
- Cursor size: `18`
- Font: `Adwaita Sans 11`

### Chunk 1: Default variables block (DONE)
- Add a small, editable variable block at the top of `bin/apply-gtk-qt-everforest.sh` with the defaults above.
- Ensure these values are the single source of truth for GTK settings and gsettings calls.

### Chunk 2: Qt palette file (Everforest dark-hard) (DONE)
- Create an Everforest `everforest.conf` for qt5ct/qt6ct using the qtct color-scheme format.
- Place it in `~/.config/qt5ct/everforest.conf` and `~/.config/qt6ct/everforest.conf` or a shared path.
- Map the Everforest dark-hard palette into the `active_colors`, `inactive_colors`, and `disabled_colors` lists.

### Chunk 3: Qt config updater (preserve sections)
- Update `~/.config/qt5ct/qt5ct.conf` and `~/.config/qt6ct/qt6ct.conf` to enforce the `[Appearance]` keys:
  - `color_scheme_path=<path to everforest.conf>`
  - `custom_palette=true`
  - `style=Fusion`
  - `standard_dialogs=default` (Qt5) / `xdgdesktopportal` (Qt6)
- Preserve `[Fonts]`, `[Interface]`, and other sections.

### Chunk 4: GTK settings + GTK4 link
- Write `~/.config/gtk-3.0/settings.ini` and `~/.config/gtk-4.0/settings.ini` using the variable block values.
- Implement theme discovery across `~/.themes`, `~/.local/share/themes`, `/usr/share/themes` (prefer gtk-3.0 + gtk-4.0).
- If `gtk-4.0` exists inside the Everforest theme directory, link it into `~/.config/gtk-4.0/`.
- Apply `gsettings` keys; warn if `gsettings` is unavailable.

### Chunk 5: Script assembly + warnings (DONE)
- Assemble `bin/apply-gtk-qt-everforest.sh` with strict mode and minimal output.
- Warn if `qt5ct`/`qt6ct` or `gsettings` are missing; continue for remaining steps.
- Warn if `QT_QPA_PLATFORMTHEME` is not `qt6ct`.

### Chunk 6: Optional --sync-root flag (DONE)
- Add a `--sync-root` flag that links `/root/.config/gtk-3.0` and `/root/.config/gtk-4.0` to the user directories.
- Do nothing unless the flag is explicitly passed.
