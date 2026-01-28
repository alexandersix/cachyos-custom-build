#!/bin/bash

set -euo pipefail

lock_file="/tmp/waybar-rebar.lock"
exec 200>"$lock_file"
flock -n 200 || exit 0

pkill -x waybar || true
sleep 0.2

if pgrep -x waybar >/dev/null; then
  pkill -9 -x waybar || true
  sleep 0.2
fi

if pgrep -x waybar >/dev/null; then
  exit 1
fi

(
  exec 200>&-
  waybar &
)
