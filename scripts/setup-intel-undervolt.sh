#!/bin/bash
# =============================================================================
# Intel Undervolt Configuration
# =============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

readonly CONFIG_FILE="/etc/intel-undervolt.conf"

# User Settings:
# CPU Core: -125
# GPU (and iGPU/Unslice): -65
# CPU Cache: -65 (Explicitly not 125)
readonly CPU_OFFSET="-125"
readonly GPU_OFFSET="-65"
readonly CACHE_OFFSET="-65"

main() {
    require_root
    log_step "Configuring Intel Undervolt..."

    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Config file $CONFIG_FILE not found."
        exit 1
    fi

    # 1. Enable Daemon
    sed -i 's/^enable no/enable yes/' "$CONFIG_FILE"

    # 2. CPU Core (Index 0)
    if grep -q "undervolt 0 'CPU'" "$CONFIG_FILE"; then
        sed -i "s/^undervolt 0 .*/undervolt 0 'CPU' ${CPU_OFFSET}/" "$CONFIG_FILE"
        log_info "Set CPU Core to ${CPU_OFFSET}mV"
    fi

    # 3. GPU (Index 1)
    if grep -q "undervolt 1 'GPU'" "$CONFIG_FILE"; then
        sed -i "s/^undervolt 1 .*/undervolt 1 'GPU' ${GPU_OFFSET}/" "$CONFIG_FILE"
        log_info "Set GPU to ${GPU_OFFSET}mV"
    fi

    # 4. CPU Cache (Index 2)
    if grep -q "undervolt 2 'CPU Cache'" "$CONFIG_FILE"; then
        sed -i "s/^undervolt 2 .*/undervolt 2 'CPU Cache' ${CACHE_OFFSET}/" "$CONFIG_FILE"
        log_info "Set CPU Cache to ${CACHE_OFFSET}mV"
    fi

    # 5. System Agent / Analog I/O (often related to iGPU stability)
    # Explicitly setting these to match GPU if that was the intent of "and and igpu", 
    # otherwise leaving 0. Assuming 'GPU' covers the main slice.

    # 6. Set Interval
    sed -i 's/^interval .*/interval 5000/' "$CONFIG_FILE"

    # 7. Apply Service
    systemd_enable_service "intel-undervolt.service" --now
    
    log_ok "Intel undervolt configured"
}

main "$@"
