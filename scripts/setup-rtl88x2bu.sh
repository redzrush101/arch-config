#!/bin/bash

echo "--> Configuring RTL88x2BU Driver..."

# 1. Blacklist the in-kernel driver (rtw88_8822bu) to prevent conflict
# As per instructions: echo "blacklist rtw88_8822bu" > /etc/modprobe.d/rtw8822bu.conf
BLACKLIST_FILE="/etc/modprobe.d/rtw8822bu.conf"

echo "    Checking blacklist configuration..."
if [ ! -f "$BLACKLIST_FILE" ] || ! grep -q "blacklist rtw88_8822bu" "$BLACKLIST_FILE"; then
    echo "blacklist rtw88_8822bu" > "$BLACKLIST_FILE"
    echo "    [OK] Blacklisted kernel driver (rtw88_8822bu) in $BLACKLIST_FILE"
else
    echo "    [SKIP] Kernel driver already blacklisted"
fi

# 2. Force USB 3.0 Mode
# As per instructions: create /etc/modprobe.d/99-RTL88x2BU.conf with options
OPTIONS_FILE="/etc/modprobe.d/99-RTL88x2BU.conf"

echo "    Checking USB 3.0 forcing configuration..."
if [ ! -f "$OPTIONS_FILE" ] || ! grep -q "rtw_switch_usb_mode=1" "$OPTIONS_FILE"; then
    echo "options 88x2bu rtw_switch_usb_mode=1" > "$OPTIONS_FILE"
    echo "    [OK] Forced USB 3.0 mode in $OPTIONS_FILE"
else
    echo "    [SKIP] USB 3.0 mode already configured"
fi

# 3. Reload module logic (Notification only)
# Since dcli runs this during installs, we usually rely on a reboot or manual reload
# to avoid breaking network during the script run.
echo "    [NOTE] If you have just installed this for the first time, please reboot."
