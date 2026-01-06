#!/bin/bash

# 1. Check for flags
USE_FREEZE=false
while [[ "$#" -gt 0 ]]; do
  case $1 in
  -f | --freeze) USE_FREEZE=true ;;
  *)
    echo "Unknown parameter passed: $1"
    exit 1
    ;;
  esac
  shift
done

# 2. Setup variables
DIR="$HOME/Pictures/Screenshots"
FILENAME="$DIR/satty-$(date +'%Y%m%d-%H%M%S').png"
mkdir -p "$DIR"

# 3. Optional: Engage Wayfreeze
# Only runs if -f or --freeze was passed
WF_PID=""
if [ "$USE_FREEZE" = true ]; then
  if command -v wayfreeze >/dev/null 2>&1; then
    wayfreeze &
    WF_PID=$!
    # Small sleep to ensure the freeze window is rendered before we select
    sleep 0.1
  else
    echo "Wayfreeze requested but not found. Proceeding without it."
  fi
fi

# 4. Run slurp (Optimized visibility settings)
# # -d: Show dimensions
# NOTE: Mango `blur` MUST be set to 0 here or otherwise overridden in the config
GEOM=$(slurp -d)

# 5. Cleanup Wayfreeze immediately (if it was used)
if [ -n "$WF_PID" ]; then
  kill $WF_PID 2>/dev/null
fi

# 6. Exit if user cancelled selection
if [ -z "$GEOM" ]; then
  exit 0
fi

# 7. Capture and open in Satty
grim -g "$GEOM" - | satty --filename - --output-filename "$FILENAME"

# # 1. Setup variables
# DIR="$HOME/Pictures/Screenshots"
# FILENAME="$DIR/satty-$(date +'%Y%m%d-%H%M%S').png"
#
# # 2. Ensure directory exists
# mkdir -p "$DIR"
#
# # 3. Run wayfreeze in background (if available) to pause the screen
# # We capture its PID to kill it later.
# if command -v wayfreeze >/dev/null 2>&1; then
#   wayfreeze &
#   WF_PID=$!
#   # Give wayfreeze a split second to initialize so it catches the screen state
#   sleep 0.1
# fi
#
# # 4. Run slurp (with the fix for the "hole punch" transparency issue)
# # -d: Show dimensions
# # -b: Selection background color (00000000 = fully transparent)
# # -c: Border color (ff0000ff = solid red for visibility)
# # -w: Border weight (2px)
# GEOM=$(slurp -d -b 00000000 -c ff0000ff -w 2)
#
# # 5. Cleanup wayfreeze immediately
# if [ -n "$WF_PID" ]; then
#   kill $WF_PID 2>/dev/null
# fi
#
# # 6. Exit if user cancelled
# if [ -z "$GEOM" ]; then
#   exit 0
# fi
#
# # 7. Capture and open in Satty
# grim -g "$GEOM" - | satty --filename - --output-filename "$FILENAME"
#
# # 1. Define the directory and filename
# # We use $HOME explicitly to be safe, though ~ usually works.
# DIR="$HOME/Pictures/Screenshots"
# FILENAME="$DIR/satty-$(date +'%Y%m%d-%H%M%S').png"
#
# # 2. Ensure the directory exists
# # mkdir -p will create the folder if it's missing, and do nothing if it's there.
# mkdir -p "$DIR"
#
# # 3. Run slurp
# # -d: Show dimensions
# # -b: Selection background color (00000000 = fully transparent)
# # -c: Border color (ff0000ff = solid red for visibility)
# # -w: Border weight (2px)
# # (Your styling preferences are preserved here)
# GEOM=$(slurp -d -b 00000000 -c ff0000ff -w 2)
#
# # 4. Check if user cancelled
# if [ -z "$GEOM" ]; then
#   exit 0
# fi
#
# # 5. Capture and pipe to Satty
# # We pass the pre-calculated $FILENAME to satty.
# grim -g "$GEOM" - | satty --filename - --output-filename "$FILENAME"
