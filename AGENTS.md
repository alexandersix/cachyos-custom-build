# six-os Agent Guide

This repo is a personal Linux desktop setup with dotfiles and helper scripts for MangoWM, Waybar, SwayNC, Wlogout, Rofi, Ghostty, Tmux, and related theming.
Most files are config or shell scripts; there is no compiled code or test framework.

## Repo Layout
- `bin/` helper scripts and system setup scripts
- `mango/` MangoWM configuration split into .conf files
- `waybar/` Waybar `config.jsonc` and `style.css`
- `swaync/` SwayNC `config.json`, `configSchema.json`, and `style.css`
- `wlogout/` menu `layout`, `style.css`, and icons
- `rofi/` `config.rasi` and `theme.rasi`
- `btop/` `btop.conf` and theme selection settings
- `ghostty/` terminal `config` and `theme`
- `tmux/` `tmux.conf`, `theme.conf`, and plugin submodules
- `qutebrowser/` `config.py`, `themes/current.py`, bookmarks, quickmarks
- `mpv/` `mpv.conf`
- `sddm/` `sddm.conf` (installed to `/etc/sddm.conf`)
- `way-displays/` `cfg.yaml` display layout config
- `themes/` per-app theme assets (GTK/Qt/Waybar/Rofi/Wlogout/Ghostty/Tmux/Qutebrowser/Btop/SDDM)
- `specs/` documentation and theming notes

## Environment Assumptions
- Arch-based system with `pacman` and `paru` available.
- Wayland session with MangoWM, Waybar, and SwayNC as primary components.
- Configs are expected to be copied into `$HOME/.config` (see `bin/install_configs.sh`).

## Common Scripts & Entrypoints
- `bin/install_configs.sh <repo-root>` copies configs into `$HOME/.config`, backs up existing configs, and handles `/etc/sddm.conf` and `~/.local/share/themes`.
- `bin/apply-theme.sh <theme> [--sync-root]` applies theme assets across GTK/Qt/Waybar/Rofi/Wlogout/Ghostty/Tmux/Qutebrowser/Btop/SDDM.
- `bin/apply-gtk-qt-everforest.sh [--sync-root]` applies GTK/Qt settings directly (Everforest defaults).
- `bin/setup.sh` and `bin/system-setup/*.sh` are manual system setup checklists/installers.
- `bin/rebar.sh` restarts Waybar; `bin/start-waybar.sh` launches it.
- `bin/screenshot.sh`, `bin/screenrecord.sh`, `bin/lock.sh`, `bin/wallpaper.sh` are end-user tools.

## Build / Lint / Test
- There is no build, lint, or test runner configured in this repo.
- "Single test" is manual: run the specific script or reload the app you changed.
- MangoWM: reload config with `SUPER+r` (see `mango/config.conf`).
- Waybar: restart with `bin/rebar.sh` or start with `bin/start-waybar.sh`.
- SwayNC: restart `swaync` (or log out/in) after editing `swaync/config.json` or `swaync/style.css`.
- Wlogout: run `wlogout` from a Wayland session to verify `wlogout/layout` and `wlogout/style.css`.
- Rofi: run `rofi -show drun` to validate `rofi/config.rasi` and `rofi/theme.rasi`.
- Ghostty: relaunch Ghostty or send `pkill -USR2 ghostty` after editing `ghostty/theme`.
- Tmux: `tmux source-file ~/.config/tmux/tmux.conf` to reload.
- Qutebrowser: restart qutebrowser or run `:config-source` to reload `qutebrowser/config.py`.
- Btop: launch/relaunch `btop` after switching themes to validate `btop/btop.conf` and `~/.config/btop/themes/current.theme`.
- MPV: launch mpv to validate `mpv/mpv.conf`.
- Optional: `shellcheck bin/*.sh` if ShellCheck is installed.

## Safety Notes
- Many scripts call `sudo pacman` or `paru` and will modify the system.
- Treat `bin/system-setup/*.sh` and `bin/setup.sh` as destructive; do not run them automatically.
- `bin/install_configs.sh` and `bin/apply-theme.sh` can touch `/etc/sddm.conf` and system theme dirs; only run when asked.
- Prefer to add comments about side effects rather than silently changing behavior.

## Code Style Guidelines
### General
- Make small, targeted edits; avoid sweeping reformatting.
- Preserve existing whitespace, indentation, and comment styles.
- Keep non-ASCII glyphs only in files that already use them (icons, UI labels).
- Imports/deps: keep them minimal; Mango `source=...` and Tmux plugins are the only includes; add new packages to `bin/system-setup/*.sh`.

### Bash Scripts (`bin/*.sh`)
- Use `#!/bin/bash`; prefer `set -euo pipefail` for scripts that change the system.
- Quote all variable expansions (`"$VAR"`) and paths.
- Use `[[ ... ]]` for tests and `case`/`getopts` for flags.
- Use arrays for package lists and expand with `"${array[@]}"`.
- Keep function-local variables `local` inside functions.
- Validate inputs early, print usage, and exit non-zero on failure; avoid silent overwrites.
- Prefer `command -v tool` checks before optional dependencies; use `sudo` only where required.
- Keep emoji/status markers if the script already uses them.

### MangoWM Config (`mango/*.conf`)
- One setting per line using `key=value` with no spaces.
- Use `#` comments and section headers (see `mango/appearance.conf`).
- Keep `source=./file.conf` entries grouped at top of `mango/config.conf`.
- Keybinds use comma-separated fields: `bind=MOD,KEY,action,...`.
- Keep numeric and color values in existing formats (hex with `0x...ff`).

### Waybar (`waybar/config.jsonc`, `waybar/style.css`)
- `config.jsonc` uses JSONC: 2-space indent, trailing commas allowed, `//` comments.
- Keep module lists ordered left/center/right and aligned with existing patterns.
- `style.css` uses `@define-color` variables and 2-space indentation; keep consistent.
- Reuse existing font family (`Iosevka`) unless intentionally changed.

### SwayNC (`swaync/config.json`, `swaync/style.css`)
- `config.json` is strict JSON: 2-space indent and no trailing commas.
- Keep schema reference at top and maintain key ordering when editing nearby settings.
- `style.css` uses CSS variables in `:root`; extend variables before adding raw literals.
- Avoid reformatting large sections; touch only what you change.

### Way-Displays (`way-displays/cfg.yaml`)
- Preserve uppercase keys (`ARRANGE`, `ALIGN`, etc.) and existing comments.
- Use 2-space indentation for lists and mappings.
- Keep quoted regex values in single quotes when used.

### Rofi (`rofi/config.rasi`, `rofi/theme.rasi`)
- Use Rasi syntax with `:` separators and semicolons.
- Keep indentation consistent (2 spaces in `config.rasi`, 4 spaces in `theme.rasi`).
- Favor variables defined in the `*` block for colors and reuse them.

### Wlogout (`wlogout/layout`, `wlogout/style.css`)
- `layout` is a list of JSON-like blocks; keep the spacing and ` "key" : "value" ` style.
- `style.css` uses tabs in some sections; preserve existing indentation and selector order.
- Icon paths are absolute; do not change unless the system paths change.

### Tmux (`tmux/tmux.conf`, `tmux/theme.conf`)
- Keep the header comment block intact.
- Use `set -g` / `set-option` and `bind` in the same style as existing lines.
- Plugin list and `run '~/.tmux/plugins/tpm/tpm'` stay at the bottom.
- Treat `tmux/plugins/*` as vendor code; avoid editing unless asked.

### Qutebrowser (`qutebrowser/*.py`, `qutebrowser/themes/*.py`)
- Keep `config.load_autoconfig()` before `config.source("themes/current.py")`.
- Use 4-space indentation; keep imports minimal (`typing` only when needed).
- Colors and font constants use `snake_case` and hex strings.
- `themes/current.py` is applied by `bin/apply-theme.sh`; update `themes/<name>/qutebrowser/*.py` for theme sources.

### Other Configs (Ghostty/MPV/SDDM)
- Ghostty: one setting per line; keep blank lines between logical groups; follow local spacing around `=`.
- MPV: INI-style `key=value` with `#` comments; keep sections grouped.
- SDDM: keep INI sections intact; avoid reordering keys.

### Themes (`themes/<name>/...`)
- Treat `themes/<name>` as the source of truth for theme assets used by `bin/apply-theme.sh`.
- Keep per-app subpaths aligned with the script expectations (gtk/qt/waybar/rofi/wlogout/ghostty/tmux/qutebrowser/sddm).

## Naming Conventions
- Script files: kebab-case in `bin/` (e.g., `start-waybar.sh`).
- Config directories: match app names (`waybar`, `swaync`, `rofi`, etc.).
- Use lower-case keys where the target app expects them; Mango keys are snake_case.
- Use clear, descriptive variable names in scripts (`OUTPUT_DIR`, `MONITOR`).

## Change Checklist
- Update both config and any dependent scripts if you change keybinds.
- If a script references a path, ensure the directory exists or create it.
- If you add new packages, add them to the relevant `bin/system-setup/*.sh` list.
- Keep theme colors and fonts consistent across Waybar, Rofi, SwayNC, and Qutebrowser.
- Note any required manual reload steps in your response.

## Cursor / Copilot Rules
- No `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md` files were found in this repo.

## Agent Workflow Expectations
- Make small, targeted edits; avoid sweeping reformatting.
- If a change is app-specific, note the manual reload command in your PR/response.
- Keep configs for each app self-contained within its directory.
- Avoid running system-setup scripts unless explicitly requested.
- If uncertain about a system side effect, add a comment and ask.
- Keep emoji usage consistent with existing files that already use them.
