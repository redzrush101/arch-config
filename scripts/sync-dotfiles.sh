#!/bin/bash

# =============================================================================
# Dotfiles Sync Script - Copy-based (no symlinks)
# Syncs between ~/.config and arch-config/dotfiles/niri/
# =============================================================================

# 1. Detect the real user (since this script may run as root)
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="$(whoami)"
    REAL_HOME="$HOME"
fi

# 2. Find script directory and define paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
DOTFILES_DIR="$REPO_ROOT/dotfiles/niri"  # <-- Now in niri subfolder
CONFIG_DIR="$REAL_HOME/.config"

# Folders to sync
FOLDERS=("niri" "waybar" "nvim" "foot" "mako" "helix")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Dotfiles Sync ===${NC}"
echo "    User:       $REAL_USER"
echo "    Repo:       $DOTFILES_DIR"
echo "    Config:     $CONFIG_DIR"
echo ""

# =============================================================================
# Function: Check if files differ (returns 0 if different, 1 if same)
# =============================================================================
files_differ() {
    local src="$1"
    local dst="$2"
    
    if [ ! -e "$dst" ]; then
        return 0  # Destination doesn't exist = different
    fi
    
    # Compare directories recursively
    if [ -d "$src" ]; then
        diff -rq "$src" "$dst" > /dev/null 2>&1
        return $?
    else
        diff -q "$src" "$dst" > /dev/null 2>&1
        return $?
    fi
}

# =============================================================================
# Function: Get newest modification time in a directory
# =============================================================================
get_newest_mtime() {
    local dir="$1"
    if [ -d "$dir" ]; then
        find "$dir" -type f -printf '%T@\n' 2>/dev/null | sort -rn | head -1
    elif [ -f "$dir" ]; then
        stat -c '%Y' "$dir" 2>/dev/null
    else
        echo "0"
    fi
}

# =============================================================================
# Function: Copy with proper ownership
# =============================================================================
copy_with_ownership() {
    local src="$1"
    local dst="$2"
    
    # Create parent directory if needed
    mkdir -p "$(dirname "$dst")"
    
    # Copy (use -a to preserve attributes, -T to handle directories properly)
    if [ -d "$src" ]; then
        cp -aT "$src" "$dst"
    else
        cp -a "$src" "$dst"
    fi
    
    # Fix ownership if running as root
    if [ "$(id -u)" -eq 0 ]; then
        chown -R "$REAL_USER:$REAL_USER" "$dst"
    fi
}

# =============================================================================
# Function: Sync a single folder
# =============================================================================
sync_folder() {
    local folder="$1"
    local repo_path="$DOTFILES_DIR/$folder"
    local config_path="$CONFIG_DIR/$folder"
    
    echo -e "${BLUE}Checking:${NC} $folder"
    
    # Case 1: Repo has it, config doesn't - copy TO config
    if [ -d "$repo_path" ] && [ ! -e "$config_path" ]; then
        echo -e "    ${GREEN}[DEPLOY]${NC} Copying to ~/.config/$folder"
        copy_with_ownership "$repo_path" "$config_path"
        return
    fi
    
    # Case 2: Config has it, repo doesn't - copy TO repo
    if [ ! -e "$repo_path" ] && [ -d "$config_path" ]; then
        echo -e "    ${YELLOW}[CAPTURE]${NC} Copying from ~/.config/$folder to repo"
        mkdir -p "$(dirname "$repo_path")"
        cp -a "$config_path" "$repo_path"
        return
    fi
    
    # Case 3: Both exist - check which is newer
    if [ -d "$repo_path" ] && [ -d "$config_path" ]; then
        if files_differ "$repo_path" "$config_path"; then
            local repo_mtime=$(get_newest_mtime "$repo_path")
            local config_mtime=$(get_newest_mtime "$config_path")
            
            if (( $(echo "$config_mtime > $repo_mtime" | bc -l) )); then
                echo -e "    ${YELLOW}[SYNC ←]${NC} ~/.config/$folder is newer, updating repo"
                rm -rf "$repo_path"
                cp -a "$config_path" "$repo_path"
            else
                echo -e "    ${GREEN}[SYNC →]${NC} Repo is newer, updating ~/.config/$folder"
                rm -rf "$config_path"
                copy_with_ownership "$repo_path" "$config_path"
            fi
        else
            echo -e "    ${NC}[OK]${NC} Already in sync"
        fi
        return
    fi
    
    # Case 4: Neither exists
    if [ ! -e "$repo_path" ] && [ ! -e "$config_path" ]; then
        echo -e "    ${RED}[SKIP]${NC} Not found in repo or config"
        return
    fi
}

# =============================================================================
# Main: Ensure directories exist
# =============================================================================

# Create dotfiles/niri directory if it doesn't exist
mkdir -p "$DOTFILES_DIR"

# Create .config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"
if [ "$(id -u)" -eq 0 ]; then
    chown "$REAL_USER:$REAL_USER" "$CONFIG_DIR"
fi

# =============================================================================
# Main: Sync each folder
# =============================================================================

for folder in "${FOLDERS[@]}"; do
    sync_folder "$folder"
done

echo ""
echo -e "${GREEN}=== Sync Complete ===${NC}"
