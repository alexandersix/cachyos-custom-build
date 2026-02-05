#!/bin/bash

# Check if a directory was provided
if [ -z "$1" ]; then
  echo "Usage: $0 /path/to/source_configs"
  exit 1
fi

SOURCE_DIR=$(realpath "$1")
TARGET_DIR="$HOME/.config"

# Ensure target .config exists
mkdir -p "$TARGET_DIR"

echo "Processing directories in: $SOURCE_DIR"
echo "------------------------------------------"

for folder in "$SOURCE_DIR"/*/; do
  folder_name=$(basename "$folder")

  # --- SPECIAL CASE: SDDM ---
  if [ "$folder_name" == "sddm" ]; then
    themes_source="$folder/sddm.conf"
    themes_target="/etc/sddm.conf"

    if [ -f "$themes_source" ]; then
      echo "🛡️  Handling SDDM configuration (requires sudo):"
      if [ -L "$themes_target" ] && [ ! -e "$themes_target" ]; then
        sudo rm "$themes_target"
        sudo ln -s "$themes_source" "$themes_target"
        echo "   🔧 Fixed broken SDDM symlink."
      elif [ -e "$themes_target" ]; then
        echo "   ✅ SDDM config already exists (Skipping)."
      else
        sudo ln -s "$themes_source" "$themes_target"
        echo "   🚀 Created SDDM symlink to /etc/sddm.conf."
      fi
    fi
    continue # Skip the default .config logic for this folder
  fi

  # --- SPECIAL CASE: themes ---
  if [ "$folder_name" == "themes" ]; then
    echo "WE ARE IN THEMES"
    themes_source="$folder/"
    themes_target="$HOME/.local/share/themes"

    if [ -d "$themes_source" ]; then
      echo "WE ARE IN FIRST CONDITIONAL"
      echo "🛡️  Handling themes directory:"
      if [ -L "$themes_target" ] && [ ! -e "$themes_target" ]; then
        rm "$themes_target"
        ln -s "$themes_source" "$themes_target"
        echo "   🔧 Fixed broken themes symlink."
      elif [ -e "$themes_target" ]; then
        echo "   ✅ themes directory already exists (Skipping)."
      else
        ln -s "$themes_source" "$themes_target"
        echo "   🚀 Created themes symlink to /$HOME/.local/share/themes."
      fi
    fi
    continue # Skip the default .config logic for this folder
  fi

  # --- DEFAULT LOGIC: $HOME/.config ---
  target_path="$TARGET_DIR/$folder_name"

  if [ -L "$target_path" ]; then
    if [ ! -e "$target_path" ]; then
      echo "🔧 Fixing broken symlink: $folder_name"
      rm "$target_path"
      ln -s "$folder" "$target_path"
    else
      echo "✅ Valid symlink already exists: $folder_name (Skipping)"
    fi
  elif [ -d "$target_path" ]; then
    echo "⚠️  Warning: A physical directory already exists at $target_path. Skipping."
  else
    echo "🚀 Creating new symlink: $folder_name"
    ln -s "$folder" "$target_path"
  fi
done

echo "------------------------------------------"
echo "Done!"
