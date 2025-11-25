#!/bin/bash
# =============================================================================
# Common Library - Shared functions for all scripts
# Source this file: source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
# =============================================================================

# Prevent multiple inclusion
[[ -n "${_COMMON_LOADED:-}" ]] && return 0
readonly _COMMON_LOADED=1

# =============================================================================
# Colors
# =============================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# =============================================================================
# Logging Functions
# =============================================================================
log_info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_skip()  { echo -e "${CYAN}[SKIP]${NC} $*"; }
log_step()  { echo -e "${BLUE}-->${NC} $*"; }

# =============================================================================
# User Detection (handles sudo context)
# =============================================================================
get_real_user() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        echo "$SUDO_USER"
    else
        whoami
    fi
}

get_real_home() {
    local user
    user=$(get_real_user)
    getent passwd "$user" | cut -d: -f6
}

# =============================================================================
# Privilege Checks
# =============================================================================
require_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

require_user() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should NOT be run as root"
        exit 1
    fi
}

# =============================================================================
# File Operations
# =============================================================================

# Ensure a file contains a specific line
# Usage: ensure_line_in_file "line content" "/path/to/file"
ensure_line_in_file() {
    local line="$1"
    local file="$2"
    
    if [[ ! -f "$file" ]] || ! grep -qF "$line" "$file"; then
        echo "$line" >> "$file"
        return 0  # Changed
    fi
    return 1  # Already exists
}

# Write content to file only if different
# Usage: write_file_if_changed "content" "/path/to/file"
write_file_if_changed() {
    local content="$1"
    local file="$2"
    
    if [[ ! -f "$file" ]] || [[ "$(cat "$file" 2>/dev/null)" != "$content" ]]; then
        echo "$content" > "$file"
        return 0  # Changed
    fi
    return 1  # No change
}

# Create parent directories if needed
ensure_parent_dir() {
    local file="$1"
    local dir
    dir=$(dirname "$file")
    [[ -d "$dir" ]] || mkdir -p "$dir"
}

# =============================================================================
# Systemd Helpers
# =============================================================================

# Enable and optionally start a systemd service
# Usage: systemd_enable_service "service-name" [--now]
systemd_enable_service() {
    local service="$1"
    local start_now="${2:-}"
    
    systemctl daemon-reload
    
    if ! systemctl is-enabled --quiet "$service" 2>/dev/null; then
        if [[ "$start_now" == "--now" ]]; then
            systemctl enable --now "$service"
            log_ok "Enabled and started $service"
        else
            systemctl enable "$service"
            log_ok "Enabled $service"
        fi
    else
        log_skip "$service already enabled"
    fi
}

# Create a oneshot systemd service
# Usage: create_oneshot_service "name" "description" "exec_command" ["after_target"]
create_oneshot_service() {
    local name="$1"
    local description="$2"
    local exec_cmd="$3"
    local after="${4:-multi-user.target}"
    local service_path="/etc/systemd/system/${name}.service"
    
    cat > "$service_path" <<EOF
[Unit]
Description=$description
After=$after

[Service]
Type=oneshot
ExecStart=$exec_cmd

[Install]
WantedBy=$after
EOF
    
    log_ok "Created $service_path"
}

# =============================================================================
# Config File Helpers (for modprobe, etc.)
# =============================================================================

# Set a modprobe option
# Usage: set_modprobe_option "filename" "module" "options"
set_modprobe_option() {
    local filename="$1"
    local module="$2"
    local options="$3"
    local file="/etc/modprobe.d/${filename}.conf"
    local content="options $module $options"
    
    if write_file_if_changed "$content" "$file"; then
        log_ok "Set modprobe options in $file"
        return 0
    else
        log_skip "Modprobe options already configured"
        return 1
    fi
}

# Blacklist a kernel module
# Usage: blacklist_module "filename" "module_name"
blacklist_module() {
    local filename="$1"
    local module="$2"
    local file="/etc/modprobe.d/${filename}.conf"
    local content="blacklist $module"
    
    if write_file_if_changed "$content" "$file"; then
        log_ok "Blacklisted $module in $file"
        return 0
    else
        log_skip "$module already blacklisted"
        return 1
    fi
}

# =============================================================================
# GRUB Helpers
# =============================================================================

# Add kernel parameters to GRUB
# Usage: add_grub_params "param1 param2 param3"
add_grub_params() {
    local params="$1"
    local grub_file="/etc/default/grub"
    local needs_update=false
    
    [[ ! -f "$grub_file" ]] && { log_error "GRUB config not found"; return 1; }
    
    for param in $params; do
        if ! grep -q "$param" "$grub_file"; then
            needs_update=true
            break
        fi
    done
    
    if $needs_update; then
        # Backup first
        cp "$grub_file" "${grub_file}.bak"
        
        # Add params (handles both empty and non-empty GRUB_CMDLINE_LINUX_DEFAULT)
        sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"$params /" "$grub_file"
        
        log_ok "Added GRUB params: $params"
        log_info "Regenerating GRUB config..."
        grub-mkconfig -o /boot/grub/grub.cfg
        return 0
    else
        log_skip "GRUB params already configured"
        return 1
    fi
}

# =============================================================================
# Path Helpers
# =============================================================================

# Get the directory where the calling script lives
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[1]}")" && pwd
}

# Get the repo root (assumes scripts are in scripts/)
get_repo_root() {
    dirname "$(get_script_dir)"
}

# =============================================================================
# Ownership Helpers
# =============================================================================

# Fix ownership for files created as root but meant for the user
fix_user_ownership() {
    local path="$1"
    local user
    user=$(get_real_user)
    
    if [[ $EUID -eq 0 ]] && [[ -e "$path" ]]; then
        chown -R "${user}:${user}" "$path"
    fi
}
