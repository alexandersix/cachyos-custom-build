# Neovim Theme Manifest

This document defines the data-only Neovim theme manifest used by system themes.

## Location

Each installed system theme may provide a manifest at:

`themes/<theme-name>/nvim/theme.lua`

At runtime, Neovim discovers manifests from installed themes under:

`~/.local/share/themes/<theme-name>/nvim/theme.lua`

## Goals

- Map the active system theme to a Neovim colorscheme
- Keep plugin specs present for all installed themes so Lazy can keep them installed
- Let new themes be added by dropping in a single manifest file

## Schema (v1)

Required fields:

- `schema_version` (number): must be `1`
- `colorscheme` (string): colorscheme name to apply (e.g. `everforest`)
- `plugin.repo` (string): plugin repo in `owner/name` format

Optional fields:

- `background` (string): `"dark"` or `"light"`
- `priority` (number): Lazy plugin priority (default `1000`)
- `plugin.name` (string): explicit Lazy plugin name
- `plugin.main` (string): plugin `main` module
- `plugin.opts` (table): setup options passed to the plugin

## Data-Only Rule

Manifest files must return plain data only:

- allowed: `nil`, `boolean`, `number`, `string`, `table`
- not allowed: functions, userdata, threads

This keeps third-party manifests predictable and safer to consume.

## Template

```lua
return {
  schema_version = 1,
  colorscheme = "your-colorscheme",
  background = "dark",
  priority = 1000,
  plugin = {
    repo = "owner/repo",
    name = "repo",
    main = "repo",
    opts = {},
  },
}
```

## Runtime Behavior

- Active system theme is read from `~/.local/share/current-theme`
- Theme plugins are discovered from installed manifests
- Active theme colorscheme is applied via LazyVim options
- Fallback colorscheme is `habamax` if mapping fails or manifest is missing
- `:SixThemeReload` reloads the active system theme in the current Neovim session
- `:SixThemeStatus` shows resolved theme state and warnings

## Third-Party Theme Onboarding

1. Place theme assets under `~/.local/share/themes/<theme-name>/...`
2. Add `~/.local/share/themes/<theme-name>/nvim/theme.lua`
3. Switch to that system theme
4. Restart Neovim once to let Lazy pick up any newly discovered plugin spec
5. Use `:SixThemeReload` for in-session theme reapply after switching themes
