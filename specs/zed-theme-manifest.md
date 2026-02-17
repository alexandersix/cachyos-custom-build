# Zed Theme Manifest

This document defines how Zed themes are stored in six-os system themes.

## Location

Each source theme provides a Zed theme file at:

`themes/<theme-name>/zed/theme.json`

Themes may optionally provide a preferred installed Zed theme name at:

`themes/<theme-name>/zed/preferred-theme`

The base config ships a default runtime file at:

`zed/themes/current.json`

After install, theme assets are available at:

`~/.local/share/themes/<theme-name>/zed/theme.json`

When applying a theme, `bin/apply-theme.sh` copies the selected file to:

`~/.config/zed/themes/current.json`

## Runtime Contract

- Theme schema must be `https://zed.dev/schema/themes/v0.2.0.json`
- Theme family files are strict JSON (2-space indentation, no trailing commas)
- Runtime theme name is fixed to `Six OS Current`
- `zed/settings.json` defaults to `Six OS Current`; preferred installed themes can override at apply time

This keeps switching simple: only one runtime file (`current.json`) is replaced.

## Preferred Theme Selection

If `themes/<theme-name>/zed/preferred-theme` exists, `bin/apply-theme.sh` reads the preferred
theme name and checks whether it exists in discovered Zed theme sources:

- `~/.config/zed/themes`
- `~/.local/share/zed/extensions/installed`
- common bundled theme locations based on the active `zed` binary path

If found, that preferred name is written to `~/.config/zed/settings.json` as the dark theme.
If not found, the script falls back to `Six OS Current`.

## Required File Shape

Each `theme.json` should contain exactly one dark theme variant for now:

```json
{
  "$schema": "https://zed.dev/schema/themes/v0.2.0.json",
  "name": "Six OS",
  "author": "Alexander Six",
  "themes": [
    {
      "name": "Six OS Current",
      "appearance": "dark",
      "style": {
        "editor.background": "#000000ff"
      }
    }
  ]
}
```

## Palette Guidance

- Use existing app theme sources to stay aligned (Waybar/Qutebrowser/Ghostty)
- Prefer Ghostty ANSI colors for `terminal.ansi.*`
- Keep text/background contrast readable in editor, panel, and tab surfaces

## Validation

- `jq empty themes/*/zed/theme.json`
- Apply and verify runtime file changes:
  - `bin/apply-theme.sh <theme-name>`
  - check `~/.config/zed/themes/current.json`
- If a preferred theme is configured, confirm `~/.config/zed/settings.json` uses it
  when available, otherwise `Six OS Current`
- Restart Zed after switching themes
