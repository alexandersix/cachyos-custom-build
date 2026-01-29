#!/bin/bash

set -euo pipefail

packages=(
  "btop"
  "eza"
  "fastfetch"
  "figlet"
  "firefox"
  "flatpak"
  "fzf"
  "ghostty"
  "git"
  "github-cli"
  "gum"
  "gvfs"
  "imagemagick"
  "jq"
  "lazygit"
  "libreoffice-fresh"
  "nautilus"
  "neovim"
  "okular"
  "qutebrowser"
  "ristretto"
  "rsync"
  "tmux"
  "unzip"
  "wget"
  "yazi"
)

aur_packages=(
  "1password"
  "1password-cli"
  "flatseal"
  "gimp"
  "kdenlive"
  "lazydocker"
  "obs-studio"
  "obsidian"
  "omarchy-chromium-bin"
  "python-hatchling"
  "selectdefaultapplication-git"
  "smug"
)

# Must come before installing 1Password
curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import # get signing key

sudo pacman -Su --needed --noconfirm "${packages[@]}"

paru -Syu --noconfirm "${aur_packages[@]}"
