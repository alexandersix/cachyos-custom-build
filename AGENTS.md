# six-os Agent Guide

This repo is a personal Linux desktop setup with dotfiles and helper scripts for MangoWM, Waybar, SwayNC, Wlogout, Rofi, Ghostty, and Tmux.
Most files are config or shell scripts; there is no compiled code or test framework.

## Repo Layout
- `bin/` contains helper scripts and system setup scripts
- `mango/` contains MangoWM configuration split into .conf files
- `waybar/` contains Waybar `config.jsonc` and `style.css`
- `swaync/` contains SwayNC `config.json` and `style.css`
- `wlogout/` contains menu `layout` and `style.css`
- `rofi/` contains `config.rasi` and theme file
- `ghostty/` contains terminal config
- `tmux/` contains `tmux.conf` and plugin submodules

## Environment Assumptions
- Arch-based system with `pacman` and `paru` available.
- Wayland session with MangoWM, Waybar, and SwayNC as primary components.
- Configs are expected to be symlinked into `$HOME/.config` (see `bin/symlink.sh`).

## Common Scripts & Entrypoints
- `bin/symlink.sh <repo-root>` links configs into `$HOME/.config` and handles `/etc/sddm.conf` specially.
- `bin/setup.sh` is a manual checklist for system setup and theming.
- `bin/system-setup/000_system_setup.sh` bootstraps base packages and paru.
- `bin/system-setup/001_install_desktop_environment.sh` installs MangoWM + desktop packages.
- `bin/system-setup/008_install_developer_tooling.sh` installs dev tools and language managers.
- `bin/rebar.sh` restarts Waybar; `bin/start-waybar.sh` launches it.
- `bin/screenshot.sh` uses grim/slurp/satty; add `--freeze` to use wayfreeze if installed.
- `bin/screenrecord.sh` toggles gpu-screen-recorder and notifies on failure.
- `bin/lock.sh` runs swaylock with visual effects.
- `bin/wallpaper.sh` uses swww; it expects the wallpaper path to exist.

## Build / Lint / Test
- There is no build, lint, or test runner configured in this repo.
- "Single test" is manual: run the specific script or reload the specific app you changed.
- MangoWM: reload config with the keybind `SUPER+r` (see `mango/config.conf`).
- Waybar: restart with `bin/rebar.sh` or start with `bin/start-waybar.sh`.
- Wlogout: run `wlogout` from a Wayland session to verify `wlogout/layout` and `wlogout/style.css`.
- Rofi: run `rofi -show drun` to validate `rofi/config.rasi` and `rofi/everforest.rasi`.
- Ghostty: relaunch Ghostty to pick up `ghostty/config` changes.
- SwayNC: restart `swaync` (or log out/in) after editing `swaync/config.json` or `swaync/style.css`.
- Shell scripts: run the script directly (e.g., `bin/screenshot.sh`) and watch for errors.
- Optional: `shellcheck bin/*.sh` if ShellCheck is installed.

## Safety Notes
- Many scripts call `sudo pacman` or `paru` and will modify the system.
- Treat `bin/system-setup/*.sh` and `bin/setup.sh` as destructive; do not run them automatically.
- Prefer to add comments about side effects rather than silently changing behavior.
- When adding new scripts, document required packages or services in the script itself.

## Code Style Guidelines
### Bash Scripts (`bin/*.sh`)
- Use `#!/bin/bash` and prefer `set -euo pipefail` for scripts that change the system.
- Quote all variable expansions (`"$VAR"`), especially paths.
- Prefer `$HOME` over `~` in scripts for predictable expansion.
- Use `[[ ... ]]` for tests and `case`/`getopts` for flags (see `bin/screenrecord.sh`).
- Use arrays for package lists and expand with `"${array[@]}"`.
- Keep function-local variables `local` inside functions.
- Prefer `command -v tool` checks before optional dependencies.
- Print actionable errors and exit non-zero on failure (see `bin/screenshot.sh`).
- Keep indentation consistent with the file (2 spaces in most scripts).
- Avoid backticks; use `$(...)` command substitution.
- Keep emoji/status markers if the script already uses them (e.g., `bin/symlink.sh`).

### MangoWM Config (`mango/*.conf`)
- One setting per line using `key=value` with no spaces.
- Use `#` comments and section headers (see `mango/appearance.conf`).
- Keep `source=./file.conf` entries grouped at top of `mango/config.conf`.
- Keybinds use comma-separated fields: `bind=MOD,KEY,action,...`.
- Keep numeric and color values in existing formats (hex with `0x...ff`).

### Waybar (`waybar/config.jsonc`, `waybar/style.css`)
- `config.jsonc` uses JSONC: 2-space indent, trailing commas allowed, `//` comments.
- Keep module lists ordered left/center/right and aligned with existing patterns.
- Use quoted strings and explicit objects; avoid reformatting to minified JSON.
- `style.css` uses `@define-color` variables and 2-space indentation; keep consistent.
- Reuse existing font family (`Iosevka`) unless intentionally changed.

### SwayNC (`swaync/config.json`, `swaync/style.css`)
- `config.json` is strict JSON: 2-space indent and no trailing commas.
- Keep schema reference at top and maintain key ordering when editing nearby settings.
- `style.css` is long-form and uses CSS variables in `:root`; extend variables before adding raw literals.
- Avoid reformatting large sections; touch only what you change.

### Way-Displays (`way-displays/cfg.yaml`)
- Preserve uppercase keys (`ARRANGE`, `ALIGN`, etc.) and existing comments.
- Use 2-space indentation for lists and mappings.
- Keep quoted regex values in single quotes when used.

### Rofi (`rofi/*.rasi`)
- Use Rasi syntax with `:` separators and semicolons.
- Keep indentation consistent (4 spaces in `rofi/everforest.rasi`).
- Favor variables defined in the `*` block for colors and reuse them.

### Wlogout (`wlogout/layout`, `wlogout/style.css`)
- `layout` is a list of JSON-like blocks; keep the spacing and ` "key" : "value" ` style.
- `style.css` uses tabs in some sections; preserve existing indentation and selector order.
- Icon paths are absolute; do not change unless the system paths change.

### Ghostty (`ghostty/config`)
- One setting per line; keep blank lines between logical groups.
- Follow local spacing around `=` in the section you edit.

### Tmux (`tmux/tmux.conf`)
- Keep the header comment block intact.
- Use `set -g` / `set-option` and `bind` in the same style as existing lines.
- Plugin list and `run '~/.tmux/plugins/tpm/tpm'` stay at the bottom.

## Imports / Dependencies
- There are no code imports; the main "includes" are Mango `source=...` lines and Tmux plugin declarations.
- Add new Mango config files by adding a `source=./new-file.conf` entry in `mango/config.conf` and commit the file.
- Avoid introducing new external dependencies unless they are installed in `bin/system-setup/*.sh`.

## Naming Conventions
- Script files: kebab-case in `bin/` (e.g., `start-waybar.sh`).
- Config directories: match app names (`waybar`, `swaync`, `rofi`, etc.).
- Use lower-case keys where the target app expects them; Mango keys are snake_case.
- Use clear, descriptive variable names in scripts (`OUTPUT_DIR`, `MONITOR`).

## Error Handling & Safety
- Fail fast in scripts that alter system state; `set -euo pipefail` is preferred.
- Validate inputs early and print usage on missing arguments (see `bin/symlink.sh`).
- Avoid silent overwrites of user config; check for existing files before linking or copying.
- Use `sudo` only where required (e.g., `/etc/sddm.conf` in `bin/symlink.sh`).
- When adding destructive operations, add a comment explaining the impact.

## Formatting Defaults
- Do not reflow or normalize whitespace across files; match the local style.
- Keep existing comment styles (`#`, `//`, `/* */`) per file type.
- Do not introduce non-ASCII characters unless the file already uses them.
- Many configs include icon glyphs; if editing those files, preserve existing icon characters.

## Change Checklist
- Update both config and any dependent scripts if you change keybinds.
- If a script references a path, ensure the directory exists or create it.
- If you add new packages, add them to the relevant `bin/system-setup/*.sh` list.
- Keep theme colors and fonts consistent across Waybar, Rofi, and SwayNC.
- Note any required manual reload steps in your response.

## Cursor / Copilot Rules
- No `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md` files were found in this repo.

## Agent Workflow Expectations
- Make small, targeted edits; avoid sweeping reformatting.
- If a change is app-specific, note the manual reload command in your PR/response.
- When adding new scripts, update the relevant system-setup list if packages are required.
- Keep configs for each app self-contained within its directory.
- Avoid running system-setup scripts unless explicitly requested.
- If uncertain about a system side effect, add a comment and ask.
- Keep emoji usage consistent with existing files that already use them.
