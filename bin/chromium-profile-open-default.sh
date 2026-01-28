#!/bin/bash

set -euo pipefail

CONFIG_DIR="$HOME/.config/chromium"
DEFAULT_PROFILE_FILE="$CONFIG_DIR/profile-default.json"
FALLBACK_PROFILE_DIR="Default"

if ! command -v chromium >/dev/null 2>&1; then
  echo "chromium not found in PATH"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq not found in PATH"
  exit 1
fi

profile_dir="$FALLBACK_PROFILE_DIR"

if [[ -f "$DEFAULT_PROFILE_FILE" ]]; then
  stored_dir=$(jq -r '.dir // empty' "$DEFAULT_PROFILE_FILE" 2>/dev/null || true)
  if [[ -n "$stored_dir" ]]; then
    profile_dir="$stored_dir"
  fi
fi

if [[ -d "$CONFIG_DIR/$profile_dir" ]]; then
  exec chromium --new-window --profile-directory="$profile_dir"
fi

if [[ -d "$CONFIG_DIR/$FALLBACK_PROFILE_DIR" ]]; then
  exec chromium --new-window --profile-directory="$FALLBACK_PROFILE_DIR"
fi

exec chromium --new-window
