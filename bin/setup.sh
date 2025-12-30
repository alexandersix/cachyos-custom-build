#!/bin/bash

# Update the system packages installed w/ installer
sudo pacman -Syu

# Install the tiling window compositor
paru -Syu mangowc-git

# Install waybar
sudo pacman -Syu waybar

# Install wallpaper manager
sudo pacman -Syu swww # TODO: change to awww once next swww release occurs (they're changing their name)

# Install graphical polkit
sudo pacman -Syu polkit-gnome

# Install keyring & GUI keyring manager
sudo pacman -Syu gnome-keyring seahorse

# Install notifications system
sudo pacman -Syu swaync
sudo usermod -a -G "${USER}"

# Install session system
sudo pacman -Syu uwsm

# Install terminal emulator
sudo pacman -Syu ghostty

# Install desktop greeter
sudo pacman -Syu sddm

sudo systemctl enable sddm.service
paru -Syu sddm-silent-theme

# Copy default mango config
mkdir ~/.config/mango
cp /etc/mango/config.conf ~/.config/mango/config.conf

# Set up initial overrides (this will likely just be copying a default config)
# Change terminal launch to SUPER Space = ghostty
# Add browser keybind to SUPER b = firefox

# Install application launcher
paru -Syu walker elephant elephant-desktopapplications elephant-providerlist
elephant service enable
systemctl --user start elephant.service

sudo pacman -Syu rofi

# Install brightness control
sudo pacman -Syu brightnessctl

# Install volume packages
sudo pacman -Syu pamixer pavucontrol wiremix

# Install bluetooth
sudo pacman -Syu bluez bluez-utils blueman

# Install networking
sudo pacman -Syu network-manager-applet nm-connection-editor

# Install power profiles
sudo pacman -Syu upower

# Install idle, lock, logout, etc.
sudo pacman -Syu swayidle wlogout
paru -Syu swaylock-effects-git wayland-logout

# Install clipboard managment system
sudo pacman -Syu wl-clipboard cliphist

# Install screenshot/screen recording packages
sudo pacman -Syu grim slurp satty
pary -Syu wl-screenrec

# Install night light
sudo pacman -Syu wlsunset

# Install file managers
sudo pacman -Syu nautilus yazi

# Install theming systems
sudo pacman -Syu nwg-look qt5ct qt6ct

# Install monitor management
sudo pacman -Syu wlr-randr
paru -Syu way-displays

# Install portals
sudo pacman -Syu xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk

# Install videos & codecs
sudo pacman -Syu vlc vlc-plugin-ffmpeg

# Install gaming meta packages
sudo pacman -Syu cachyos-gaming-meta cachyos-gaming-applications

# Install bolt OSRS launcher (likely should not be in the base package)
paru -Syu bolt-launcher

# Install virtualization systems
sudo pacman -Syu libvirt gnome-boxes virt-manager qemu-full dnsmasq
sudo usermod -aG libvirt $USER
sudo systemctl enable --now libvirtd

# Install Docker
sudo pacman -Syu docker docker-buildx docker-compose

sudo systemctl enable docker.service # change to `systemctl start` if you don't want to auto-start docker upon system boot

sudo usermod -aG docker $USER # add user to docker group to prevent needing `sudo`

# Install password manager
curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import # get signing key

paru -Syu 1password 1password-cli

# Install extra utilities
sudo pacman -Syu github-cli imagemagick jq fzf flatpak git figlet wget unzip gum rsync neovim eza fastfetch gvfs btop lazygit

paru -Syu flatseal lazydocker

# Set up fonts
sudo pacman -Syu fontconfig font-manager ttc-iosevka

mkdir $HOME/.fonts

# Install languages

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Set up git
git config --global user.email "alexanderhsix@gmail.com"
git config --global user.name "Alex Six"

# Dotfiles
# Install them!

# zshrc
# Add {full path}/.config/bin to the path for scripts to work
