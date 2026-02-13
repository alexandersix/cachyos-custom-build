#!/bin/bash

set -euo pipefail

if [[ "$#" -lt 3 ]]; then
  # Prompt for user input
  echo "Enter app name: "

  read -r APP_NAME

  echo "Enter app url: "

  read -r APP_URL

  echo "Enter icon url (must be png): "

  read -r ICON_URL
else
  APP_NAME="$1"
  APP_URL="$2"
  ICON_URL="$3"
fi

# Validate

if [[ -z "$APP_NAME" || -z "$APP_URL" || -z "$ICON_URL" ]]; then
  echo "Please enter all parameters."
  exit 1
fi

if ! [[ -d "$HOME/.local/share/applications/icons" ]]; then
  mkdir -p "$HOME/.local/share/applications/icons"
fi

ICON_DIR="$HOME/.local/share/applications/icons"

ICON_PATH="$ICON_DIR/$APP_NAME.png"

if curl -sL -o "$ICON_PATH" "$ICON_URL"; then
  echo "Icon downloaded successfully."
else
  echo "Failed to download icon"
  exit 2
fi

# Set the exec command
EXEC_COMMAND="$HOME/.config/bin/launch-webapp.sh $APP_URL"

# Create application .desktop file
DESKTOP_FILE="$HOME/.local/share/applications/$APP_NAME.desktop"

cat >"$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Name=$APP_NAME
Comment=$APP_NAME
Exec=$EXEC_COMMAND
Terminal=false
Type=Application
Icon=$ICON_PATH
StartupNotify=true
EOF

chmod +x "$DESKTOP_FILE"

echo "Done."
