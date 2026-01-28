#!/bin/bash

set -euo pipefail

packages=(
  "grim"
  "satty"
  "slurp"
  "vlc"
  "vlc-plugin-ffmpeg"
)

aur_packages=(
  "gpu-screen-recorder"
  "wayfreeze-git"
)

sudo pacman -Su --needed --noconfirm "${packages[@]}"

paru -Syu --noconfirm "${aur_packages[@]}"

mkdir $HOME/Pictures
mkdir $HOME/Videos
mkdir $HOME/Videos/Screencasts
