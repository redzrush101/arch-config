#!/bin/bash
# =============================================================================
# Gigabyte Motherboard Wakeup Fix
# Disables GPP0 as ACPI wakeup source to prevent random wake from sleep
# =============================================================================

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
readonly SERVICE_NAME="wakeup-disable-GPP0"
readonly WAKEUP_DEVICE="GPP0"

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
    require_root
    log_step "Applying Gigabyte Motherboard Wakeup Fix..."
    
    # Create the systemd service
    local exec_cmd='/bin/bash -c "grep -q '\''GPP0.*enabled'\'' /proc/acpi/wakeup && echo GPP0 > /proc/acpi/wakeup || true"'
    
    create_oneshot_service \
        "$SERVICE_NAME" \
        "Disable ${WAKEUP_DEVICE} as ACPI wakeup source (Gigabyte Fix)" \
        "$exec_cmd"
    
    # Enable the service
    systemd_enable_service "${SERVICE_NAME}.service" --now
    
    log_ok "Gigabyte wakeup fix applied"
}

main "$@"
