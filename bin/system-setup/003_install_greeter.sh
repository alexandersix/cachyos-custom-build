#!/bin/bash

set -euo pipefail

packages=(
  "sddm"
)

aur_packages=(
  "sddm-silent-theme"
)

sudo pacman -Su --needed --noconfirm "${packages[@]}"

paru -Syu --noconfirm "${aur_packages[@]}"
