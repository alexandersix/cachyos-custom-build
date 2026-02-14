local M = {}

M.fallback_colorscheme = "habamax"
M.default_priority = 1000

local uv = vim.uv or vim.loop
local commands_ready = false

local function data_home()
  return vim.env.XDG_DATA_HOME or (vim.env.HOME .. "/.local/share")
end

local function themes_root()
  return data_home() .. "/themes"
end

local function current_theme_file()
  return data_home() .. "/current-theme"
end

local function file_exists(path)
  local stat = uv.fs_stat(path)
  return stat and stat.type == "file"
end

local function dir_exists(path)
  local stat = uv.fs_stat(path)
  return stat and stat.type == "directory"
end

local function trim(value)
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Six Theme" })
end

local function read_current_theme_name()
  local path = current_theme_file()
  if not file_exists(path) then
    return nil, string.format("Current theme file not found: %s", path)
  end

  local lines = vim.fn.readfile(path, "", 1)
  if #lines == 0 then
    return nil, string.format("Current theme file is empty: %s", path)
  end

  local theme_name = trim(lines[1] or "")
  if theme_name == "" then
    return nil, string.format("Current theme file is empty: %s", path)
  end

  return theme_name, nil
end

local function list_installed_theme_names()
  local root = themes_root()
  if not dir_exists(root) then
    return {}
  end

  local names = {}
  for _, name in ipairs(vim.fn.readdir(root)) do
    local path = root .. "/" .. name
    if dir_exists(path) then
      table.insert(names, name)
    end
  end

  table.sort(names)
  return names
end

local function is_data_only(value, seen)
  local value_type = type(value)
  if value_type == "nil" or value_type == "boolean" or value_type == "number" or value_type == "string" then
    return true
  end

  if value_type ~= "table" then
    return false
  end

  seen = seen or {}
  if seen[value] then
    return true
  end

  seen[value] = true

  for key, nested_value in pairs(value) do
    if not is_data_only(key, seen) then
      return false
    end

    if not is_data_only(nested_value, seen) then
      return false
    end
  end

  return true
end

local function infer_plugin_name(repo)
  local name = repo:match("/([^/]+)$")
  return name or repo
end

local function load_manifest_file(path)
  local ok, manifest = pcall(dofile, path)
  if not ok then
    return nil, string.format("Failed to load %s: %s", path, manifest)
  end

  return manifest, nil
end

local function normalize_manifest(theme_name, manifest, manifest_path)
  if type(manifest) ~= "table" then
    return nil, string.format("Manifest must return a table: %s", manifest_path)
  end

  if not is_data_only(manifest) then
    return nil, string.format("Manifest must be data-only (no functions): %s", manifest_path)
  end

  if manifest.schema_version ~= 1 then
    return nil, string.format("Unsupported schema_version in %s (expected 1)", manifest_path)
  end

  if type(manifest.colorscheme) ~= "string" or manifest.colorscheme == "" then
    return nil, string.format("Missing colorscheme in %s", manifest_path)
  end

  if manifest.background ~= nil and manifest.background ~= "dark" and manifest.background ~= "light" then
    return nil, string.format("background must be 'dark' or 'light' in %s", manifest_path)
  end

  if manifest.priority ~= nil and type(manifest.priority) ~= "number" then
    return nil, string.format("priority must be a number in %s", manifest_path)
  end

  local plugin = manifest.plugin
  if type(plugin) ~= "table" then
    return nil, string.format("Missing plugin table in %s", manifest_path)
  end

  if type(plugin.repo) ~= "string" or plugin.repo == "" then
    return nil, string.format("Missing plugin.repo in %s", manifest_path)
  end

  if plugin.name ~= nil and (type(plugin.name) ~= "string" or plugin.name == "") then
    return nil, string.format("plugin.name must be a non-empty string in %s", manifest_path)
  end

  if plugin.main ~= nil and (type(plugin.main) ~= "string" or plugin.main == "") then
    return nil, string.format("plugin.main must be a non-empty string in %s", manifest_path)
  end

  if plugin.opts ~= nil and type(plugin.opts) ~= "table" then
    return nil, string.format("plugin.opts must be a table in %s", manifest_path)
  end

  local normalized = {
    theme_name = theme_name,
    manifest_path = manifest_path,
    colorscheme = manifest.colorscheme,
    background = manifest.background,
    priority = manifest.priority or M.default_priority,
    plugin = {
      repo = plugin.repo,
      name = plugin.name or infer_plugin_name(plugin.repo),
      main = plugin.main,
      opts = plugin.opts and vim.deepcopy(plugin.opts) or nil,
    },
  }

  return normalized, nil
end

local function apply_local_overrides(record)
  if record.colorscheme ~= "everforest" then
    return
  end

  local opts = record.plugin.opts or {}
  opts.on_highlights = function(hl, palette)
    hl.CurSearch = { fg = palette.bg0, bg = palette.statusline1 }
    hl.IncSearch = { fg = palette.bg0, bg = palette.statusline1 }
    hl.Search = { fg = palette.bg0, bg = palette.statusline1 }
    hl.Visual = { fg = palette.fg, bg = palette.bg_green }
  end
  record.plugin.opts = opts
end

local function collect_manifests()
  local manifests = {}
  local warnings = {}

  for _, theme_name in ipairs(list_installed_theme_names()) do
    local manifest_path = string.format("%s/%s/nvim/theme.lua", themes_root(), theme_name)
    if file_exists(manifest_path) then
      local manifest, load_error = load_manifest_file(manifest_path)
      if not manifest then
        table.insert(warnings, load_error)
      else
        local normalized, normalize_error = normalize_manifest(theme_name, manifest, manifest_path)
        if not normalized then
          table.insert(warnings, normalize_error)
        else
          apply_local_overrides(normalized)
          manifests[theme_name] = normalized
        end
      end
    end
  end

  return manifests, warnings
end

local function sorted_records(manifests)
  local names = {}
  for theme_name in pairs(manifests) do
    table.insert(names, theme_name)
  end

  table.sort(names)

  local records = {}
  for _, theme_name in ipairs(names) do
    table.insert(records, manifests[theme_name])
  end

  return records
end

local function resolve_state()
  local manifests, warnings = collect_manifests()
  local active_theme, theme_error = read_current_theme_name()
  if theme_error then
    table.insert(warnings, theme_error)
  end

  local active_manifest = active_theme and manifests[active_theme] or nil
  if active_theme and not active_manifest then
    table.insert(warnings, string.format("No Neovim manifest found for active theme '%s'", active_theme))
  end

  return {
    active_theme = active_theme,
    active_manifest = active_manifest,
    manifests = manifests,
    warnings = warnings,
    resolved_colorscheme = active_manifest and active_manifest.colorscheme or M.fallback_colorscheme,
    resolved_background = active_manifest and active_manifest.background or nil,
  }
end

local function notify_warnings(warnings)
  for _, warning in ipairs(warnings) do
    notify(warning, vim.log.levels.WARN)
  end
end

local function lazy_has_plugin(plugin_name)
  local ok, lazy_config = pcall(require, "lazy.core.config")
  if not ok then
    return false
  end

  return lazy_config.plugins[plugin_name] ~= nil
end

local function lazy_load_plugin(plugin_name)
  local ok, lazy = pcall(require, "lazy")
  if not ok then
    return false, "lazy.nvim is not available"
  end

  local loaded, load_error = pcall(lazy.load, { plugins = { plugin_name }, wait = true })
  if not loaded then
    return false, tostring(load_error)
  end

  return true, nil
end

local function apply_colorscheme(colorscheme)
  local ok, error_message = pcall(vim.cmd.colorscheme, colorscheme)
  if not ok then
    return false, tostring(error_message)
  end

  return true, nil
end

local function state_lines(state)
  local lines = {
    string.format("Active system theme: %s", state.active_theme or "(none)"),
    string.format("Resolved colorscheme: %s", state.resolved_colorscheme),
    string.format("Installed Neovim theme manifests: %d", vim.tbl_count(state.manifests)),
    string.format("Fallback colorscheme: %s", M.fallback_colorscheme),
  }

  if state.active_manifest then
    table.insert(lines, string.format("Active plugin: %s", state.active_manifest.plugin.repo))
  else
    table.insert(lines, "Active plugin: (fallback)")
  end

  if #state.warnings > 0 then
    for _, warning in ipairs(state.warnings) do
      table.insert(lines, string.format("Warning: %s", warning))
    end
  end

  return lines
end

function M.lazy_specs()
  local state = resolve_state()
  local specs = {}
  local seen_plugins = {}

  for _, record in ipairs(sorted_records(state.manifests)) do
    local plugin_name = record.plugin.name
    if seen_plugins[plugin_name] then
      notify(string.format("Skipping duplicate theme plugin name '%s'", plugin_name), vim.log.levels.WARN)
    else
      seen_plugins[plugin_name] = true

      local is_active = state.active_manifest and state.active_manifest.theme_name == record.theme_name
      local spec = {
        record.plugin.repo,
        name = plugin_name,
        lazy = not is_active,
        priority = record.priority,
      }

      if record.plugin.main then
        spec.main = record.plugin.main
      end

      if record.plugin.opts then
        spec.opts = record.plugin.opts
      end

      table.insert(specs, spec)
    end
  end

  table.insert(specs, {
    "LazyVim/LazyVim",
    opts = function(_, opts)
      if state.resolved_background then
        vim.o.background = state.resolved_background
      end

      opts.colorscheme = state.resolved_colorscheme
    end,
  })

  return specs
end

function M.reload_theme()
  local state = resolve_state()
  notify_warnings(state.warnings)

  if state.resolved_background then
    vim.o.background = state.resolved_background
  end

  if state.active_manifest then
    local plugin_name = state.active_manifest.plugin.name
    if lazy_has_plugin(plugin_name) then
      local loaded, load_error = lazy_load_plugin(plugin_name)
      if not loaded then
        notify(string.format("Could not load plugin '%s': %s", plugin_name, load_error), vim.log.levels.WARN)
      end
    else
      notify(
        string.format(
          "Theme plugin '%s' is not in the current Lazy spec. Restart Neovim to pick up newly installed themes.",
          plugin_name
        ),
        vim.log.levels.WARN
      )
    end
  end

  local applied, apply_error = apply_colorscheme(state.resolved_colorscheme)
  if applied then
    notify(string.format("Applied Neovim colorscheme '%s'", state.resolved_colorscheme))
    return
  end

  local fallback_applied, fallback_error = apply_colorscheme(M.fallback_colorscheme)
  if fallback_applied then
    notify(
      string.format(
        "Failed to apply '%s' (%s). Falling back to '%s'.",
        state.resolved_colorscheme,
        apply_error,
        M.fallback_colorscheme
      ),
      vim.log.levels.WARN
    )
    return
  end

  notify(
    string.format(
      "Failed to apply '%s' (%s) and fallback '%s' (%s).",
      state.resolved_colorscheme,
      apply_error,
      M.fallback_colorscheme,
      fallback_error
    ),
    vim.log.levels.ERROR
  )
end

function M.show_status()
  local state = resolve_state()
  notify(table.concat(state_lines(state), "\n"))
end

function M.setup_commands()
  if commands_ready then
    return
  end

  if vim.fn.exists(":SixThemeReload") == 0 then
    vim.api.nvim_create_user_command("SixThemeReload", function()
      require("config.six_theme").reload_theme()
    end, { desc = "Reload Neovim theme from the current system theme" })
  end

  if vim.fn.exists(":SixThemeStatus") == 0 then
    vim.api.nvim_create_user_command("SixThemeStatus", function()
      require("config.six_theme").show_status()
    end, { desc = "Show system-aware Neovim theming status" })
  end

  commands_ready = true
end

return M
