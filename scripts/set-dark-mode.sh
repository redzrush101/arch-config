#!/bin/bash
# =============================================================================
# Dark Mode Configuration
# Sets up dark theme for GTK, Qt, and Wayland applications
# Should be run as the user (not root), typically from autostart
# =============================================================================

set -euo pipefail

# Note: This script runs as user, not root - lightweight, no common.sh needed

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
readonly GTK_THEME="Adwaita-dark"
readonly COLOR_SCHEME="prefer-dark"

# Environment variables to export
declare -A ENV_VARS=(
    ["QT_QPA_PLATFORM"]="wayland;xcb"
    ["QT_QPA_PLATFORMTHEME"]="gtk3"
    ["GTK_THEME"]="$GTK_THEME"
    ["MOZ_ENABLE_WAYLAND"]="1"
    ["XDG_CURRENT_DESKTOP"]="niri"
)

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------
set_gsettings() {
    if ! command -v gsettings &>/dev/null; then
        echo "[WARN] gsettings not found, skipping GTK configuration"
        return 1
    fi
    
    gsettings set org.gnome.desktop.interface color-scheme "$COLOR_SCHEME"
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"
}

export_env_vars() {
    for var in "${!ENV_VARS[@]}"; do
        export "$var"="${ENV_VARS[$var]}"
    done
}

update_dbus_environment() {
    if ! command -v dbus-update-activation-environment &>/dev/null; then
        echo "[WARN] dbus-update-activation-environment not found"
        return 1
    fi
    
    dbus-update-activation-environment --systemd "${!ENV_VARS[@]}"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    # Set GTK preferences
    set_gsettings || true
    
    # Export environment variables
    export_env_vars
    
    # Update D-Bus environment for spawned applications
    update_dbus_environment || true
}

main "$@"
