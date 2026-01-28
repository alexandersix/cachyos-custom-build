#!/bin/bash

set -euo pipefail

packages=(
)

aur_packages=(
)

sudo pacman -Su --needed --noconfirm "${packages[@]}"

paru -Syu --noconfirm "${aur_packages[@]}"
