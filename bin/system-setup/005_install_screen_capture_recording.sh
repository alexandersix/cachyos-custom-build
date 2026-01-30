#!/bin/bash

set -euo pipefail

packages=(
  "grim"
  "satty"
  "slurp"
  "mpv"
  "vlc"
  "vlc-plugin-ffmpeg"
  "yt-dlp"
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

# TODO: Set up an automated system to bring mpv-youtube-search into the correct places
# See https://github.com/willswats/mpv-youtube-search?tab=readme-ov-file for details
