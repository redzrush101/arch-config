#!/bin/bash
# =============================================================================
# Virtualization Setup (KVM/QEMU/Libvirt)
# Configures user permissions, libvirt, and IOMMU for GPU passthrough
# =============================================================================

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
readonly VIRT_GROUPS=("libvirt" "kvm" "input")
readonly LIBVIRT_CONF="/etc/libvirt/libvirtd.conf"
readonly QEMU_BRIDGE_HELPER="/usr/lib/qemu/qemu-bridge-helper"
readonly IOMMU_PARAMS="amd_iommu=on iommu=pt video=efifb:off"

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------
setup_user_groups() {
    local user="$1"
    
    log_info "Adding $user to virtualization groups..."
    
    for group in "${VIRT_GROUPS[@]}"; do
        if getent group "$group" > /dev/null 2>&1; then
            usermod -aG "$group" "$user"
            log_ok "Added to $group"
        else
            log_warn "Group $group does not exist (install libvirt first?)"
        fi
    done
}

configure_libvirtd() {
    [[ ! -f "$LIBVIRT_CONF" ]] && { log_skip "libvirtd.conf not found"; return; }
    
    log_info "Configuring libvirtd..."
    
    # Uncomment socket group and permissions
    sed -i 's/^#unix_sock_group = "libvirt"/unix_sock_group = "libvirt"/' "$LIBVIRT_CONF"
    sed -i 's/^#unix_sock_rw_perms = "0770"/unix_sock_rw_perms = "0770"/' "$LIBVIRT_CONF"
    
    log_ok "libvirtd.conf configured"
}

configure_qemu_bridge() {
    [[ ! -f "$QEMU_BRIDGE_HELPER" ]] && { log_skip "qemu-bridge-helper not found"; return; }
    
    chmod u+s "$QEMU_BRIDGE_HELPER"
    log_ok "Set SUID on qemu-bridge-helper"
}

configure_iommu() {
    log_info "Checking IOMMU configuration..."
    add_grub_params "$IOMMU_PARAMS" || true
}

enable_services() {
    log_info "Enabling libvirt services..."
    
    systemd_enable_service "libvirtd.service" --now
    systemd_enable_service "virtlogd.service" --now
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    require_root
    
    local user
    user=$(get_real_user)
    
    log_step "Configuring Virtualization for user: $user"
    
    setup_user_groups "$user"
    configure_libvirtd
    configure_qemu_bridge
    configure_iommu
    enable_services
    
    log_ok "Virtualization setup complete"
    log_warn "You may need to log out and back in for group changes to take effect"
}

main "$@"
