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
  "nautilus"
  "neovim"
  "qutebrowser"
  "rsync"
  "unzip"
  "wget"
  "yazi"
  "ristretto"
  "libreoffice-fresh"
  "okular"
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
  "tmux"
)

# Must come before installing 1Password
curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import # get signing key

sudo pacman -Su --needed --noconfirm "${packages[@]}"

paru -Syu --noconfirm "${aur_packages[@]}"
