#!/bin/bash

set -euo pipefail

services=(
  "sddm.service"
  "libvirtd"
  "docker.service"
)

for service in "${services[@]}"; do
  sudo systemctl enable "$service"
  sudo systemctl start "$service"
done
