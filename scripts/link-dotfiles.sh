#!/bin/bash

# 1. Detect the real user (since this script runs as root)
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="$(whoami)"
    REAL_HOME="$HOME"
fi

# 2. Robustly find the directory where this script lives
# This gets /home/yassin/.config/arch-config/scripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 3. Define Paths relative to the script location
# Go up one level from 'scripts' to get 'arch-config' root
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
DOTFILES_DIR="$REPO_ROOT/dotfiles"
CONFIG_DIR="$REAL_HOME/.config"

echo "--> Linking Dotfiles for user: $REAL_USER"
echo "    Repo Root: $REPO_ROOT"
echo "    Source:    $DOTFILES_DIR"
echo "    Target:    $CONFIG_DIR"

link_dir() {
    local folder="$1"
    local source="$DOTFILES_DIR/$folder"
    local target="$CONFIG_DIR/$folder"

    # Check if source exists in your repo
    if [ ! -d "$source" ]; then
        echo "    [SKIP] Source not found: $source"
        return
    fi

    # Check if target exists and is NOT a symlink (it's a real folder)
    if [ -d "$target" ] && [ ! -L "$target" ]; then
        echo "    [BACKUP] Real folder found at $target. Moving to ${target}.bak"
        mv "$target" "${target}.bak"
        chown -R "$REAL_USER:$REAL_USER" "${target}.bak"
    fi

    # Create the symlink
    ln -sf "$source" "$target"
    
    # Change ownership of the symlink to the user
    chown -h "$REAL_USER:$REAL_USER" "$target"
    
    echo "    [OK] Linked $folder"
}

# --- Folders to link ---
link_dir "niri"
link_dir "waybar"
link_dir "nvim"
link_dir "foot"
