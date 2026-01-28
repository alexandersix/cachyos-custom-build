#!/bin/bash

set -euo pipefail

# Update the system
sudo pacman -Syu

# Install paru
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

sudo loginctl enable-linger alexandersix
