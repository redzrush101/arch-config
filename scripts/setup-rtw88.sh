#!/bin/bash
# =============================================================================
# rtw88 WiFi Driver Configuration
# Blacklists in-kernel driver to favor the AUR dkms package
# =============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# The AUR package 'rtw88-dkms-git' usually installs modules named 'rtw_8822be', 'rtw_8822ce', etc.
# The kernel modules are usually 'rtw88_8822be', 'rtw88_8822ce', or just 'rtw88_core'.
# We blacklist the kernel versions to ensure DKMS loads.

# Note: Adjust exact module names if your specific card isn't 8822ce/be, 
# but this covers the common conflicts for the rtw88 family.

main() {
    require_root
    log_step "Configuring rtw88 Driver..."

    # 1. Blacklist generic in-kernel modules
    blacklist_module "rtw88-blacklist" "rtw88_8822ce"
    blacklist_module "rtw88-blacklist" "rtw88_8822be"
    blacklist_module "rtw88-blacklist" "rtw88_8723de"
    # Sometimes needed if the dkms package uses 'rtw_core' vs kernel 'rtw88_core'
    # blacklist_module "rtw88-blacklist" "rtw88_core" 

    # 2. Options (Optional: disable power saving if unstable)
    # set_modprobe_option "rtw88" "rtw_pci" "disable_aspm=1"
    
    log_info "Blacklisted kernel rtw88 modules to favor DKMS version"
    log_warn "Please reboot for WiFi driver changes to take effect"
}

main "$@"
