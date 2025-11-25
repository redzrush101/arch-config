#!/bin/bash
# =============================================================================
# Dotfiles Sync Script
# Syncs configuration files between ~/.config and arch-config/dotfiles/niri/
# Uses copy-based sync (no symlinks) with automatic conflict resolution
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Path Detection (MUST be done BEFORE sourcing common.sh)
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Source common library
source "${SCRIPT_DIR}/lib/common.sh"

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
readonly DOTFILES_SUBDIR="dotfiles/niri"
readonly FOLDERS=("niri" "waybar" "nvim" "foot" "mako" "helix" "fuzzel" "swaylock")
# -----------------------------------------------------------------------------
# Derived Paths (using pre-calculated REPO_ROOT)
# -----------------------------------------------------------------------------
REAL_USER=$(get_real_user)
REAL_HOME=$(get_real_home)
DOTFILES_DIR="${REPO_ROOT}/${DOTFILES_SUBDIR}"
CONFIG_DIR="${REAL_HOME}/.config"

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

# Check if two paths have different content
# Returns 0 if different, 1 if same
paths_differ() {
    local src="$1"
    local dst="$2"
    
    [[ ! -e "$dst" ]] && return 0
    
    if [[ -d "$src" ]]; then
        ! diff -rq "$src" "$dst" &>/dev/null
    else
        ! diff -q "$src" "$dst" &>/dev/null
    fi
}

# Get newest modification time in a directory tree
get_newest_mtime() {
    local path="$1"
    
    if [[ -d "$path" ]]; then
        find "$path" -type f -printf '%T@\n' 2>/dev/null | sort -rn | head -1 || echo "0"
    elif [[ -f "$path" ]]; then
        stat -c '%Y' "$path" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Copy preserving attributes and fix ownership if needed
copy_with_ownership() {
    local src="$1"
    local dst="$2"
    
    ensure_parent_dir "$dst"
    
    if [[ -d "$src" ]]; then
        cp -aT "$src" "$dst"
    else
        cp -a "$src" "$dst"
    fi
    
    fix_user_ownership "$dst"
}

# Sync a single folder between repo and config
sync_folder() {
    local folder="$1"
    local repo_path="${DOTFILES_DIR}/${folder}"
    local config_path="${CONFIG_DIR}/${folder}"
    
    echo -e "${BLUE}Checking:${NC} $folder"
    
    # Case 1: Only in repo -> deploy to config
    if [[ -d "$repo_path" ]] && [[ ! -e "$config_path" ]]; then
        echo -e "    ${GREEN}[DEPLOY]${NC} Copying to ~/.config/$folder"
        copy_with_ownership "$repo_path" "$config_path"
        return
    fi
    
    # Case 2: Only in config -> capture to repo
    if [[ ! -e "$repo_path" ]] && [[ -d "$config_path" ]]; then
        echo -e "    ${YELLOW}[CAPTURE]${NC} Copying to repo"
        ensure_parent_dir "$repo_path"
        cp -a "$config_path" "$repo_path"
        return
    fi
    
    # Case 3: Both exist -> sync based on modification time
    if [[ -d "$repo_path" ]] && [[ -d "$config_path" ]]; then
        if paths_differ "$repo_path" "$config_path"; then
            local repo_mtime config_mtime
            repo_mtime=$(get_newest_mtime "$repo_path")
            config_mtime=$(get_newest_mtime "$config_path")
            
            # Handle empty mtime (default to 0)
            repo_mtime=${repo_mtime:-0}
            config_mtime=${config_mtime:-0}
            
            if (( $(echo "$config_mtime > $repo_mtime" | bc -l) )); then
                echo -e "    ${YELLOW}[SYNC ←]${NC} Config is newer, updating repo"
                rm -rf "$repo_path"
                cp -a "$config_path" "$repo_path"
            else
                echo -e "    ${GREEN}[SYNC →]${NC} Repo is newer, updating config"
                rm -rf "$config_path"
                copy_with_ownership "$repo_path" "$config_path"
            fi
        else
            echo -e "    ${NC}[OK]${NC} Already in sync"
        fi
        return
    fi
    
    # Case 4: Neither exists
    echo -e "    ${RED}[SKIP]${NC} Not found in repo or config"
}

print_header() {
    echo -e "${BLUE}=== Dotfiles Sync ===${NC}"
    echo "    User:       $REAL_USER"
    echo "    Repo:       $DOTFILES_DIR"
    echo "    Config:     $CONFIG_DIR"
    echo ""
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    print_header
    
    # Validate paths
    if [[ ! -d "$REPO_ROOT" ]]; then
        log_error "Repo root not found: $REPO_ROOT"
        exit 1
    fi
    
    # Ensure directories exist
    mkdir -p "$DOTFILES_DIR"
    mkdir -p "$CONFIG_DIR"
    fix_user_ownership "$CONFIG_DIR"
    
    # Sync each folder
    for folder in "${FOLDERS[@]}"; do
        sync_folder "$folder"
    done
    
    echo ""
    echo -e "${GREEN}=== Sync Complete ===${NC}"
}

main "$@"
