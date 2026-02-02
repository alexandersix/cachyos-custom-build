#!/bin/bash

set -euo pipefail

packages=(
  kvantum
)

aur_packages=(
  everforest-gtk-theme-git
)

sudo pacman -Su --needed --noconfirm "${packages[@]}"

paru -Syu --noconfirm "${aur_packages[@]}"

# TODO: create the ~/.config/environment.d/qt.conf file (or put it in the dotfiles to be auto synced)
