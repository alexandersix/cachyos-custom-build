# Dynamic Lazyvim Theming Prompt

## Description of Project

Currently, we have a theme picker script written in this repository that allows me to select a theme
and subsequently updates and reloads all configuration files to reflect the given theme.

However, there is one glaring holdout from this list of "all" configuration files: Lazyvim.

I currently have a slightly configured version of Lazyvim installed in this Linux configuration. I
want to figure out the best way to automatically change the theme of neovim to match the
theme that is selected in the picker.

I do NOT want to automatically generate a color scheme for the existing themes (though that will
come later in the matugen theme). Instead, I would like for each theme to have a `nvim` directory
that contains a Lua file that, somehow, lists the Neovim theme plugin that needs to be installed
and activated.

Ideally, we wouldn't have to _also_ add any Neovim plugins to the Lazyvim configuration files
manually when we install them. I would like to somehow automate that process (or find another
way for the Lazy package manager to know that a theme is installed on my system and automatically
install the Neovim theme plugin that is defined in the given theme), but I don't want to have
to install/uninstall the Neovim theme plugin every time I change. I would prefer for each
theme that is installed to automatically install their given Neovim theme plugin on the next
`nvim` launch after downloading and installing the new theme.

This opens the door for people to create and distribute third-party themes.

## Summarizing Goals

In summary, I want to achieve the following:

- Automatically switch the active Neovim theme plugin when switching system themes
- Automatically install the Neovim theme plugin(s) for any newly-installed system themes upon the next `nvim` boot
- Prevent uninstalling Neovim theme plugins that are not currently active, but their corresponding system themes are still installed on the system
