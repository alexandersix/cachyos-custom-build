#!/bin/bash

set -euo pipefail

packages=(
  kvantum
)

aur_packages=(
  everforest-gtk-theme-git
  gruvbox-gtk-theme-git
  kanagawa-gtk-theme-git
  tokyonight-gtk-theme-git
)

sudo pacman -Su --needed --noconfirm "${packages[@]}"

paru -Syu --noconfirm "${aur_packages[@]}"
