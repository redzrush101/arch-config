#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run Undervolt Setup
bash "${SCRIPT_DIR}/setup-intel-undervolt.sh"

# Run WiFi Setup
bash "${SCRIPT_DIR}/setup-rtw88.sh"
