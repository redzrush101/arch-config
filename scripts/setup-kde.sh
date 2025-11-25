#!/bin/bash
# =============================================================================
# KDE & Flatpak Setup
# Enables Display Manager and adds Flatpak Remotes
# =============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

main() {
    require_root
    log_step "Configuring KDE and Flatpak..."

    # 1. Enable SDDM (Display Manager)
    systemd_enable_service "sddm.service" --now

    # 2. Add Flatpak Remote (System-wide)
    log_info "Adding Flathub remote (System)..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    
    # 3. Add Flatpak Remote (User)
    # We need to run this as the real user
    local user
    user=$(get_real_user)
    
    log_info "Adding Flathub remote (User: $user)..."
    sudo -u "$user" flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

    log_ok "KDE and Flatpak configuration complete"
}

main "$@"
