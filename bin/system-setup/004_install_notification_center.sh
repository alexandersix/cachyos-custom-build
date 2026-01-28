#!/bin/bash

set -euo pipefail

packages=(
  "swaync"
)

aur_packages=(
  ""
)

sudo pacman -Su --needed --noconfirm "${packages[@]}"

paru -Syu --noconfirm "${aur_packages[@]}"

sudo usermod -a -G "${USER}"
