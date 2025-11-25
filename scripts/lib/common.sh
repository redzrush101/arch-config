#!/bin/bash
# =============================================================================
# Common Library - Shared functions for all scripts
# Source this file: source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
#
# NOTE: Scripts should determine their own SCRIPT_DIR and REPO_ROOT BEFORE
#       sourcing this file, as BASH_SOURCE doesn't work reliably across
#       function calls.
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
ensure_line_in_file() {
    local line="$1"
    local file="$2"
    
    if [[ ! -f "$file" ]] || ! grep -qF "$line" "$file"; then
        echo "$line" >> "$file"
        return 0
    fi
    return 1
}

# Write content to file only if different
write_file_if_changed() {
    local content="$1"
    local file="$2"
    
    if [[ ! -f "$file" ]] || [[ "$(cat "$file" 2>/dev/null)" != "$content" ]]; then
        echo "$content" > "$file"
        return 0
    fi
    return 1
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
# Config File Helpers
# =============================================================================

# Set a modprobe option
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
        cp "$grub_file" "${grub_file}.bak"
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
