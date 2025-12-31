#!/bin/bash

# Update the system packages installed w/ installer
sudo pacman -Syu

# Install the tiling window compositor
paru -Syu mangowc-git

# Install waybar
sudo pacman -Syu waybar

# Install wallpaper manager
sudo pacman -Syu swww # TODO: change to awww once next swww release occurs (they're changing their name)

# TODO: update symlink script (or write custom) to move this to `.config/systemd/user`

systemctl --user enable swww.service
systemctl --user start swww.service

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

# Install browser
paru -Syu omarchy-chromium-bin

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

# Set up themes
# TODO: eventually, each premade theme directory should have its own setup.sh for this kind of stuff
sudo pacman -Syu sassc gnome-themes-extra
paru -Syu gtk-engine-murrine

mkdir -p $HOME/.config/themes/gtk/
git clone https://github.com/Fausto-Korpsvart/Everforest-GTK-Theme.git $HOME/.config/themes/gtk/everforest
$HOME/.config/themes/gtk/everforest/themes/install.sh

mkdir -p $HOME/.config/gtk-4.0/
ln -s $HOME/.themes/Everforest-Dark/ $HOME/.config/gtk-4.0/

themeName="Everforest-Dark"

# gsettings gtk (needed for window decorations in non-flatpak apps)
gsettings set org.gnome.desktop.interface gtk-theme "$themeName"
sudo gsettings set org.gnome.desktop.interface gtk-theme "$themeName"

# add new export
echo "export GTK_THEME=$themeName" >>"$HOME/.zshrc"
echo "export GTK_THEME=$themeName" | sudo tee --append "/root/.zshrc"

# flatpak
sudo flatpak override --filesystem=xdg-data/themes # only way to give access to /.local/share/themes
sudo flatpak override --env=GTK_THEME="$themeName"

# Dotfiles
# Install them!

# zshrc
# Add $HOME/.config/bin to the path for scripts to work
# Add $HOME/.config/composer to the path for scripts to work
# Add $HOME/.local/bin to the path for uv to work

# PHP
sudo pacman -Syu php php-gd php-pgsql php-sqlite

# Composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'c8b085408188070d5f52bcfe4ecfbee5f727afa458b2573b8eaaf77b3419b0bf2768dc67c86944da1544f06fa544fd47') { echo 'Installer verified'.PHP_EOL; } else { echo 'Installer corrupt'.PHP_EOL; unlink('composer-setup.php'); exit(1); }"
php composer-setup.php
php -r "unlink('composer-setup.php');"

sudo mv composer.phar /usr/local/bin/composer

# Laravel Installer
composer global require laravel/installer

# SQL TUI/GUI
paru -Syu tableplus

# curl -LsSf https://astral.sh/uv/install.sh | sh
sudo pacman -Syu uv
uv tool install harlequin
uv tool install 'harlequin[postgres]'
uv tool install 'harlequin[mysql]'
