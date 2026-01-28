#!/bin/bash

set -euo pipefail

packages=(
  "cachyos-gaming-meta"
  "cachyos-gaming-applications"
)

aur_packages=(
  "bolt-launcher"
)

sudo pacman -Su --needed --noconfirm "${packages[@]}"

paru -Syu --noconfirm "${aur_packages[@]}"
