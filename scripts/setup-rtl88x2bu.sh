#!/bin/bash
# =============================================================================
# RTL88x2BU WiFi Driver Configuration
# Blacklists in-kernel driver and forces USB 3.0 mode
# =============================================================================

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
readonly KERNEL_MODULE="rtw88_8822bu"
readonly DKMS_MODULE="88x2bu"

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    require_root
    log_step "Configuring RTL88x2BU Driver..."
    
    # 1. Blacklist the in-kernel driver to prevent conflict
    blacklist_module "rtw8822bu" "$KERNEL_MODULE"
    
    # 2. Force USB 3.0 Mode for better performance
    set_modprobe_option "99-RTL88x2BU" "$DKMS_MODULE" "rtw_switch_usb_mode=1"
    
    # 3. Notify about reboot requirement
    log_warn "If this is a fresh install, please reboot for changes to take effect"
    
    log_ok "RTL88x2BU configuration complete"
}

main "$@"
