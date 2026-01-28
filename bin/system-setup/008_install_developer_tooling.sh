#!/bin/bash

set -euo pipefail

packages=(
  "docker"
  "docker-buildx"
  "docker-compose"
  "php"
  "php-gd"
  "php-pgsql"
  "php-sqlite"
)

aur_packages=(
  "tableplus"
  "uv"
)

sudo pacman -Su --needed --noconfirm "${packages[@]}"

paru -Syu --noconfirm "${aur_packages[@]}"

# Install opencode
curl -fsSL https://opencode.ai/install | bash

# Add user to docker group
sudo usermod -aG docker $USER

# Install languages

## NVM (Node & NPM)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

## PHP

### Composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'c8b085408188070d5f52bcfe4ecfbee5f727afa458b2573b8eaaf77b3419b0bf2768dc67c86944da1544f06fa544fd47') { echo 'Installer verified'.PHP_EOL; } else { echo 'Installer corrupt'.PHP_EOL; unlink('composer-setup.php'); exit(1); }"
php composer-setup.php
php -r "unlink('composer-setup.php');"

sudo mv composer.phar /usr/local/bin/composer

### Laravel Installer
composer global require laravel/installer

# Set up git
git config --global user.email "alexanderhsix@gmail.com"
git config --global user.name "Alex Six"

# TUI DB manager
uv tool install harlequin
uv tool install 'harlequin[postgres]'
uv tool install 'harlequin[mysql]'
