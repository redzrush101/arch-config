#!/bin/bash
# =============================================================================
# Intel Undervolt Configuration
# Sets CPU and GPU voltage offsets and enables the daemon
# =============================================================================

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
readonly CONFIG_FILE="/etc/intel-undervolt.conf"

# Values requested: CPU -125, GPU -65
# Note: Usually CPU Core (0) and CPU Cache (2) must match for stability.
readonly CPU_OFFSET="-125"
readonly GPU_OFFSET="-65"

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    require_root
    log_step "Configuring Intel Undervolt..."

    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Config file $CONFIG_FILE not found. Is intel-undervolt installed?"
        exit 1
    fi

    # 1. Enable the Daemon in config
    # Changes 'enable no' to 'enable yes'
    sed -i 's/^enable no/enable yes/' "$CONFIG_FILE"

    # 2. Apply CPU Undervolt (Index 0: CPU Core)
    if grep -q "undervolt 0 'CPU'" "$CONFIG_FILE"; then
        sed -i "s/^undervolt 0 .*/undervolt 0 'CPU' ${CPU_OFFSET}/" "$CONFIG_FILE"
        log_info "Set CPU Core to ${CPU_OFFSET}mV"
    fi

    # 3. Apply GPU Undervolt (Index 1: GPU)
    if grep -q "undervolt 1 'GPU'" "$CONFIG_FILE"; then
        sed -i "s/^undervolt 1 .*/undervolt 1 'GPU' ${GPU_OFFSET}/" "$CONFIG_FILE"
        log_info "Set GPU to ${GPU_OFFSET}mV"
    fi

    # 4. Apply CPU Cache Undervolt (Index 2: CPU Cache)
    # Must usually match CPU Core
    if grep -q "undervolt 2 'CPU Cache'" "$CONFIG_FILE"; then
        sed -i "s/^undervolt 2 .*/undervolt 2 'CPU Cache' ${CPU_OFFSET}/" "$CONFIG_FILE"
        log_info "Set CPU Cache to ${CPU_OFFSET}mV"
    fi

    # 5. Apply System Agent/Analog I/O (Optional, keeping at 0 or setting if specifically needed)
    # Keeping default logic unless specified, but ensuring config is clean
    
    # 6. Set Interval
    sed -i 's/^interval .*/interval 5000/' "$CONFIG_FILE"

    log_ok "Configuration applied to $CONFIG_FILE"

    # 7. Enable and Start Systemd Service
    systemd_enable_service "intel-undervolt.service" --now

    # 8. Check status
    if systemctl is-active --quiet intel-undervolt.service; then
        log_ok "intel-undervolt is running"
        log_info "Current readings:"
        intel-undervolt read || true
    else
        log_warn "intel-undervolt service failed to start. Check logs."
    fi
}

main "$@"
