#!/bin/bash

set -euo pipefail

packages=(
  "blueman"
  "bluetui"
  "bluez"
  "bluez-utils"
  "brightnessctl"
  "cliphist"
  "gnome-keyring"
  "gst-plugin-pipewire"
  "libcanberra"
  "network-manager-applet"
  "nm-connection-editor"
  "pavucontrol"
  "pipewire"
  "pipewire-pulse"
  "playerctl"
  "polkit-gnome"
  "rofi"
  "rofi-emoji"
  "seahorse"
  "swayidle"
  "upower"
  "uwsm"
  "wireplumber"
  "wl-clipboard"
  "wlogout"
  "wlr-randr"
  "wtype"
)

aur_packages=(
  "swaylock-effects-git"
  "way-displays"
  "wayland-logout"
)

sudo pacman -Su --needed --noconfirm "${packages[@]}"

paru -Syu --noconfirm "${aur_packages[@]}"
