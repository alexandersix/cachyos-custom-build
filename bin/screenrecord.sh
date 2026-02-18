#!/bin/bash

set -euo pipefail

# doesn't work if scale is not 1.0
# TODO: eventually get portals working

# Arguments
# - -m full monitor (takes monitor name)
# - -p portal (????) - wlroots 0.20 needed

OUTPUT_DIR="$HOME/Videos/Screencasts"
WAYBAR_SCREENRECORD_SIGNAL=8

if [[ ! -d "$OUTPUT_DIR" ]]; then
  notify-send "Screen recording directory does not exist: $OUTPUT_DIR" -u critical -t 3000
  exit 1
fi

MONITOR=""

while getopts "m:" opt; do
  case $opt in
  m)
    MONITOR=$OPTARG
    ;;
  esac
done

# $1 - monitor name
start_screenrecording() {
  local filename="$OUTPUT_DIR/screenrecording-$(date +'%Y-%m-%d_%H-%M-%S').mp4"
  local region=""

  if [[ -z "$1" ]]; then
    if ! region="$(slurp -f "%wx%h+%x+%y")"; then
      return 0
    fi

    if [[ -z "$region" ]]; then
      return 0
    fi

    gpu-screen-recorder -w region -region "$region" -o "$filename" &
  else
    gpu-screen-recorder -w "$1" -o "$filename" &
  fi

  signal_waybar_screenrecord
}

signal_waybar_screenrecord() {
  pkill -RTMIN+"$WAYBAR_SCREENRECORD_SIGNAL" -x waybar >/dev/null 2>&1 || true
}

#
stop_screenrecording() {
  pkill -SIGINT -f "^gpu-screen-recorder" # SIGINT required to save video properly

  # Wait a maximum of 5 seconds to finish before hard killing
  local count=0
  while pgrep -f "^gpu-screen-recorder" >/dev/null && [ $count -lt 50 ]; do
    sleep 0.1
    count=$((count + 1))
  done

  if pgrep -f "^gpu-screen-recorder" >/dev/null; then
    pkill -9 -f "^gpu-screen-recorder"
    notify-send "Screen recording error" "Recording process had to be force-killed. Video may be corrupted." -u critical -t 5000
  else
    notify-send "Screen recording saved to $OUTPUT_DIR" -t 2000
  fi

  signal_waybar_screenrecord
}

screenrecording_active() {
  pgrep -f "^gpu-screen-recorder" >/dev/null
}

if screenrecording_active; then
  stop_screenrecording
else
  start_screenrecording "$MONITOR"
fi
