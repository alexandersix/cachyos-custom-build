#!/bin/bash

set -euo pipefail

packages=(
  "btop"
  "chromium"
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
  "telegram-desktop"
  "tmux"
  "unzip"
  "wget"
  "yazi"
  "zed"
)

aur_packages=(
  "1password"
  "1password-cli"
  "flatseal"
  "gimp"
  "kdenlive"
  "lazydocker"
  "localsend"
  "obs-studio"
  "obsidian"
  "python-hatchling"
  "selectdefaultapplication-git"
  "slack-desktop-wayland"
  "smug"
)

# Must come before installing 1Password
curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import # get signing key

sudo pacman -Su --needed --noconfirm "${packages[@]}"

paru -Syu --noconfirm "${aur_packages[@]}"

# Open firewall for localsend (pull out into a script later)
sudo ufw allow 53317/tcp
sudo ufw allow 53317/udp
sudo ufw enable # applies changes

# Install web apps
install-web-app.sh "Twitter" "https://twitter.com" "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/twitter.png"
