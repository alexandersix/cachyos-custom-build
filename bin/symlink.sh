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
    sddm_source="$folder/sddm.conf"
    sddm_target="/etc/sddm.conf"

    if [ -f "$sddm_source" ]; then
      echo "🛡️  Handling SDDM configuration (requires sudo):"
      if [ -L "$sddm_target" ] && [ ! -e "$sddm_target" ]; then
        sudo rm "$sddm_target"
        sudo ln -s "$sddm_source" "$sddm_target"
        echo "   🔧 Fixed broken SDDM symlink."
      elif [ -e "$sddm_target" ]; then
        echo "   ✅ SDDM config already exists (Skipping)."
      else
        sudo ln -s "$sddm_source" "$sddm_target"
        echo "   🚀 Created SDDM symlink to /etc/sddm.conf."
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

# for folder in "$SOURCE_DIR"/*/; do
#   # Remove trailing slash for naming
#   folder_name=$(basename "$folder")
#   target_path="$TARGET_DIR/$folder_name"
#
#   # 1. Check if the path exists and is a symbolic link
#   if [ -L "$target_path" ]; then
#     if [ ! -e "$target_path" ]; then
#       echo "🔧 Fixing broken symlink: $folder_name"
#       rm "$target_path"
#       ln -s "$folder" "$target_path"
#     else
#       echo "✅ Valid symlink already exists: $folder_name (Skipping)"
#     fi
#   # 2. Check if it's a real directory (not a link) to avoid overwriting data
#   elif [ -d "$target_path" ]; then
#     echo "⚠️  Warning: A physical directory already exists at $target_path. Skipping to prevent data loss."
#   # 3. Create new symlink
#   else
#     echo "🚀 Creating new symlink: $folder_name"
#     ln -s "$folder" "$target_path"
#   fi
# done

echo "------------------------------------------"
echo "Done!"
