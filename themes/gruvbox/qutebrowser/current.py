from typing import Any, cast

c = globals().get("c")
if c is None:
    raise RuntimeError("qutebrowser config context missing")
c = cast(Any, c)

bg0 = "#1d2021"
bg1 = "#3c3836"
bg = "#282828"
bg_dim = "#1d2021"
bg_highlight = "#504945"
fg = "#ebdbb2"
fg_dim = "#a89984"
green = "#b8bb26"
red = "#fb4934"
yellow = "#fabd2f"
blue = "#83a598"
aqua = "#8ec07c"
purple = "#d3869b"
orange = "#fe8019"

font_family = "Iosevka"
font_size = "11pt"
font = f"{font_size} {font_family}"
font_bold = f"bold {font_size} {font_family}"

c.fonts.default_family = [font_family]
c.fonts.default_size = font_size
c.fonts.completion.category = font_bold
c.fonts.completion.entry = font
c.fonts.hints = font_bold
c.fonts.keyhint = font
c.fonts.messages.error = font
c.fonts.messages.info = font
c.fonts.messages.warning = font
c.fonts.prompts = font
c.fonts.statusbar = font
c.fonts.tabs.selected = font
c.fonts.tabs.unselected = font

c.colors.tabs.bar.bg = bg_dim
c.colors.tabs.odd.bg = bg
c.colors.tabs.odd.fg = fg_dim
c.colors.tabs.even.bg = bg
c.colors.tabs.even.fg = fg_dim
c.colors.tabs.selected.odd.bg = bg1
c.colors.tabs.selected.odd.fg = fg
c.colors.tabs.selected.even.bg = bg1
c.colors.tabs.selected.even.fg = fg

c.colors.statusbar.normal.bg = bg_dim
c.colors.statusbar.normal.fg = fg
c.colors.statusbar.insert.bg = green
c.colors.statusbar.insert.fg = bg0
c.colors.statusbar.command.bg = orange
c.colors.statusbar.command.fg = bg0
c.colors.statusbar.private.bg = purple
c.colors.statusbar.private.fg = bg0
c.colors.statusbar.command.private.bg = purple
c.colors.statusbar.command.private.fg = bg0

c.colors.completion.category.bg = bg1
c.colors.completion.category.fg = fg
c.colors.completion.even.bg = bg
c.colors.completion.odd.bg = bg0
c.colors.completion.item.selected.bg = bg_highlight
c.colors.completion.item.selected.fg = fg
c.colors.completion.match.fg = green

c.colors.hints.bg = yellow
c.colors.hints.fg = bg0
c.colors.hints.match.fg = aqua

c.colors.keyhint.bg = bg1
c.colors.keyhint.fg = fg

c.colors.messages.info.bg = blue
c.colors.messages.info.fg = bg0
c.colors.messages.warning.bg = yellow
c.colors.messages.warning.fg = bg0
c.colors.messages.error.bg = red
c.colors.messages.error.fg = bg0

c.colors.prompts.bg = bg1
c.colors.prompts.fg = fg
c.colors.prompts.selected.bg = bg_highlight
c.colors.prompts.selected.fg = fg

c.colors.webpage.preferred_color_scheme = "dark"

c.tabs.padding = {"top": 6, "bottom": 6, "left": 4, "right": 4}
