# Qutebrowser Everforest Palette

All colors use #RRGGBB.

## Palette map
- bg0: #2b3339 (rofi/everforest.rasi bg0)
- bg1: #323d43 (rofi/everforest.rasi bg1)
- bg: #2d353b (waybar/style.css bg)
- bg_dim: #232a2e (waybar/style.css bgDim)
- bg_highlight: #414b50 (rofi/everforest.rasi highlight-color; themes/everforest/qt/*ct/colors/everforest.conf)
- fg: #d3c6aa (waybar/style.css fg; rofi/everforest.rasi fg0)
- fg_dim: #859289 (themes/everforest/qt/*ct/colors/everforest.conf inactive_colors)
- green: #a7c080 (waybar/style.css green; rofi/everforest.rasi accent-color)
- red: #e67e80 (waybar/style.css red; mango/appearance.conf urgentcolor)
- yellow: #dbbc7f (waybar/style.css yellow; rofi/everforest.rasi urgent-color)
- blue: #7fbbb3 (waybar/style.css blue)
- aqua: #83c092 (waybar/style.css aqua)
- purple: #d699b6 (waybar/style.css purple)
- orange: #e69875 (mango/appearance.conf globalcolor)

## Qutebrowser role mapping
### Tabs
- bar bg: bg_dim
- active bg/fg: bg1 / fg
- inactive bg/fg: bg / fg_dim
- urgent bg/fg: red / bg0

### Statusbar
- normal fg/bg: fg / bg_dim
- insert fg/bg: bg0 / green
- command fg/bg: bg0 / orange
- private fg/bg: bg0 / purple

### Completion
- category fg/bg: fg / bg1
- odd/even row bg: bg0 / bg
- selected fg/bg: fg / bg_highlight
- match fg: green

### Hints/Keyhint
- hint fg/bg: bg0 / yellow
- match fg: aqua
- keyhint fg/bg: fg / bg1

### Messages
- info fg/bg: bg0 / blue
- warning fg/bg: bg0 / yellow
- error fg/bg: bg0 / red

### Prompts
- fg/bg: fg / bg1
- selection fg/bg: fg / bg_highlight

### Webpage
- preferred_color_scheme: dark
- darkmode.enabled: true (if supported)
