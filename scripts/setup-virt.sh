#!/bin/bash

# 1. Detect the real user (since dcli runs as root)
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
else
    REAL_USER="$(whoami)"
fi

echo "--> Configuring Virtualization for user: $REAL_USER"

# 2. Add User to Groups
# libvirt: manage VMs, kvm: hardware access, input: mouse/kb passthrough
echo "    Adding $REAL_USER to libvirt, kvm, and input groups..."
usermod -aG libvirt,kvm,input "$REAL_USER"

# 3. Configure libvirtd.conf (Allow group access)
LIBVIRT_CONF="/etc/libvirt/libvirtd.conf"
if [ -f "$LIBVIRT_CONF" ]; then
    echo "    Configuring $LIBVIRT_CONF..."
    # Uncomment unix_sock_group = "libvirt"
    sed -i 's/^#unix_sock_group = "libvirt"/unix_sock_group = "libvirt"/' "$LIBVIRT_CONF"
    # Uncomment unix_sock_rw_perms = "0770"
    sed -i 's/^#unix_sock_rw_perms = "0770"/unix_sock_rw_perms = "0770"/' "$LIBVIRT_CONF"
fi

# 4. Configure QEMU (Optional: specific NVRAM/OVMF paths usually auto-detected)
# We ensure the default bridge helper has correct permissions
if [ -f "/usr/lib/qemu/qemu-bridge-helper" ]; then
    chmod u+s /usr/lib/qemu/qemu-bridge-helper
fi

# 5. GRUB Configuration (AMD IOMMU)
GRUB_FILE="/etc/default/grub"
if grep -q "amd_iommu=on" "$GRUB_FILE"; then
    echo "    [SKIP] IOMMU already enabled in GRUB."
else
    echo "    Enabling AMD IOMMU in GRUB..."
    # Append amd_iommu=on and iommu=pt to the default cmdline
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="amd_iommu=on iommu=pt video=efifb:off
 /' "$GRUB_FILE"
    
    echo "    Re-generating GRUB config..."
    grub-mkconfig -o /boot/grub/grub.cfg
fi

# 6. Enable Services
echo "    Enabling libvirtd systemd services..."
systemctl enable --now libvirtd.service
systemctl enable --now virtlogd.service
