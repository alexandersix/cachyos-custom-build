#!/bin/bash

set -euo pipefail

packages=(
  "libvirt"
  "gnome-boxes"
  "virt-manager"
  "qemu-full"
  "dnsmasq"
)

aur_packages=(
)

sudo pacman -Su --needed --noconfirm "${packages[@]}"

paru -Syu --noconfirm "${aur_packages[@]}"

mkdir $HOME/Pictures
mkdir $HOME/Videos
mkdir $HOME/Videos/Screencasts
