#!/bin/bash

SERVICE_NAME="wakeup-disable-GPP0.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"

echo "--> Applying Gigabyte Motherboard Wakeup Fix..."

# 1. Create the systemd service file
cat <<EOF > "$SERVICE_PATH"
[Unit]
Description=Disable GPP0 as ACPI wakeup source (Gigabyte Fix)
After=multi-user.target

[Service]
Type=oneshot
# Check if GPP0 is enabled before toggling it, to prevent accidentally enabling it
ExecStart=/bin/bash -c "grep -q 'GPP0.*enabled' /proc/acpi/wakeup && echo GPP0 > /proc/acpi/wakeup || true"

[Install]
WantedBy=multi-user.target
EOF

echo "    Created $SERVICE_PATH"

# 2. Reload systemd to recognize the new file
systemctl daemon-reload

# 3. Enable and Start the service immediately
if ! systemctl is-enabled --quiet "$SERVICE_NAME"; then
    systemctl enable --now "$SERVICE_NAME"
    echo "    Enabled and started $SERVICE_NAME"
else
    echo "    $SERVICE_NAME is already enabled"
fi
