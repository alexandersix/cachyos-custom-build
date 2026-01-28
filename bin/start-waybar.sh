#!/bin/bash

set -euo pipefail

if pgrep -x waybar > /dev/null; then
  exit 0
fi

sleep 1.5

if pgrep -x waybar > /dev/null; then
  exit 0
fi

waybar &
