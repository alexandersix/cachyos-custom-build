#!/bin/bash

set -euo pipefail

packages=(
  "adw-gtk-theme"
  "font-manager"
  "fontconfig"
  "gtk3"
  "gtk4"
  "kvantum"
  "kvantum-qt5"
  "matugen"
  "noto-fonts-emoji"
  "nwg-look"
  "qt5-wayland"
  "qt5ct"
  "qt6-multimedia-ffmpeg"
  "qt6-svg"
  "qt6-wayland"
  "sassc"
  "solaar"
  "swww"
  "ttc-iosevka"
  "ttf-font-awesome"
  "ttf-jetbrains-mono-nerd"
  "waybar"
  "wlsunset"
  "xdg-desktop-portal"
  "xdg-desktop-portal-gtk"
  "xdg-desktop-portal-wlr"
)

aur_packages=(
  "mangowc-git",
  "qt6ct-kde"
)

sudo pacman -Su --needed --noconfirm "${packages[@]}"

paru -Syu --noconfirm "${aur_packages[@]}"

# Copy default mango config
if [[ ! -d "$HOME/.config/mango"]]; then
  mkdir ~/.config/mango
fi

cp -f /etc/mango/config.conf ~/.config/mango/config.conf
