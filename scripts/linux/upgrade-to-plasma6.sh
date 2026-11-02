#!/usr/bin/env bash
set -euo pipefail

ROOTFS="/var/lib/raytolfas/plasma-rootfs"
BACKUP_DIR="/var/lib/raytolfas/plasma-rootfs-v5-bak"

if [ ! -d "${BACKUP_DIR}" ]; then
    echo "[plasma6] Creating fast local safety backup at ${BACKUP_DIR}..."
    cp -a "${ROOTFS}" "${BACKUP_DIR}"
fi

cleanup() {
    rm -f "${ROOTFS}/usr/sbin/policy-rc.d"
    umount -lf "${ROOTFS}/dev/pts" 2>/dev/null || true
    umount -lf "${ROOTFS}/dev" 2>/dev/null || true
    umount -lf "${ROOTFS}/sys" 2>/dev/null || true
    umount -lf "${ROOTFS}/proc" 2>/dev/null || true
}
trap cleanup EXIT

mkdir -p "${ROOTFS}/proc" "${ROOTFS}/sys" "${ROOTFS}/dev/pts" "${ROOTFS}/etc/apt/keyrings" "${ROOTFS}/etc/apt/sources.list.d" "${ROOTFS}/etc/apt/preferences.d"
mount --bind /proc "${ROOTFS}/proc"
mount --bind /sys "${ROOTFS}/sys"
mount --bind /dev "${ROOTFS}/dev"
mount --bind /dev/pts "${ROOTFS}/dev/pts"

rm -f "${ROOTFS}/etc/resolv.conf"
cp -L /etc/resolv.conf "${ROOTFS}/etc/resolv.conf"

cat << 'EOF' > "${ROOTFS}/usr/sbin/policy-rc.d"
#!/bin/sh
exit 101
EOF
chmod 0755 "${ROOTFS}/usr/sbin/policy-rc.d"

rm -f "${ROOTFS}/etc/apt/apt.conf.d/80-btrfs-auto-snapshot"

echo "[plasma6] Installing official KDE archive GPG key and repository..."
curl -fsSL https://archive.neon.kde.org/public.key | gpg --dearmor --yes -o "${ROOTFS}/etc/apt/keyrings/neon-archive.gpg"
chmod 0644 "${ROOTFS}/etc/apt/keyrings/neon-archive.gpg"

cat << 'EOF' > "${ROOTFS}/etc/apt/sources.list.d/plasma6.list"
deb [signed-by=/etc/apt/keyrings/neon-archive.gpg] https://archive.neon.kde.org/user noble main
EOF

cat << 'EOF' > "${ROOTFS}/etc/apt/preferences.d/99-raytolfas-plasma6"
Package: base-files base-files-dbgsym lsb-release neon-* distro-info* plymouth* grub*
Pin: origin "archive.neon.kde.org"
Pin-Priority: -1

Package: *
Pin: origin "archive.neon.kde.org"
Pin-Priority: 700
EOF

echo "[plasma6] Updating package indexes..."
chroot "${ROOTFS}" apt-get update

echo "[plasma6] Upgrading desktop stack to KDE Plasma 6 + Qt 6..."
chroot "${ROOTFS}" env DEBIAN_FRONTEND=noninteractive apt-get -f install -y \
    --allow-downgrades \
    -o Dpkg::Options::="--force-overwrite" \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" || true
chroot "${ROOTFS}" dpkg --configure -a || true

chroot "${ROOTFS}" env DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y \
    --allow-downgrades \
    -o Dpkg::Options::="--force-overwrite" \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold"

echo "[plasma6] Ensuring full Plasma 6, KWin 6, Aurorae, Mobile 6, Calamares, and PyQt6 modules..."
chroot "${ROOTFS}" env DEBIAN_FRONTEND=noninteractive apt-get install -y \
    --allow-downgrades \
    -o Dpkg::Options::="--force-overwrite" \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    plasma-desktop \
    plasma-workspace \
    kwin-wayland \
    kwin-x11 \
    aurorae \
    breeze \
    breeze-gtk-theme \
    kde-config-gtk-style \
    sddm \
    sddm-theme-breeze \
    systemsettings \
    dolphin \
    konsole \
    kde-spectacle \
    plasma-systemmonitor \
    plasma-nm \
    plasma-pa \
    powerdevil \
    bluedevil \
    kscreen \
    milou \
    xdg-desktop-portal-kde \
    layer-shell-qt \
    plasma-mobile \
    calamares \
    kde-cli-tools \
    libkf6config-bin \
    qdbus-qt6 \
    python3-pyqt6 \
    python3-pyqt6.qtqml \
    python3-pyqt6.qtquick \
    qml6-module-qtquick \
    qml6-module-qtquick-controls \
    qml6-module-qtquick-layouts \
    qml6-module-qtquick-window \
    qml6-module-qt5compat-graphicaleffects \
    virtualbox-guest-utils \
    virtualbox-guest-x11 \
    spice-vdagent

echo "[plasma6] Cleaning obsolete packages and APT cache..."
if ls "${ROOTFS}/boot/vmlinuz-"*cachyos* >/dev/null 2>&1; then
    chroot "${ROOTFS}" env DEBIAN_FRONTEND=noninteractive apt-get purge -y \
        linux-image-generic linux-headers-generic \
        'linux-image-6.8.0-*-generic' 'linux-modules-6.8.0-*-generic' \
        'linux-modules-extra-6.8.0-*-generic' 'linux-headers-6.8.0-*' 2>/dev/null || true
fi
chroot "${ROOTFS}" env DEBIAN_FRONTEND=noninteractive apt-get autoremove -y --purge
chroot "${ROOTFS}" apt-get clean

if [ ! -e "${ROOTFS}/usr/bin/kwriteconfig5" ] && [ -x "${ROOTFS}/usr/bin/kwriteconfig6" ]; then
    ln -sf kwriteconfig6 "${ROOTFS}/usr/bin/kwriteconfig5"
fi
if [ ! -e "${ROOTFS}/usr/bin/kreadconfig5" ] && [ -x "${ROOTFS}/usr/bin/kreadconfig6" ]; then
    ln -sf kreadconfig6 "${ROOTFS}/usr/bin/kreadconfig5"
fi
if [ ! -e "${ROOTFS}/usr/bin/qdbus" ] && [ -x "${ROOTFS}/usr/bin/qdbus6" ]; then
    ln -sf qdbus6 "${ROOTFS}/usr/bin/qdbus"
fi

echo "[plasma6] Fetching Fluent-kde and Fluent-icon-theme for Plasma 6..."
mkdir -p /var/lib/raytolfas/src-themes
if [ ! -d /var/lib/raytolfas/src-themes/fluent-kde ]; then
    git clone --depth=1 https://github.com/vinceliuice/Fluent-kde.git /var/lib/raytolfas/src-themes/fluent-kde
fi
if [ ! -d /var/lib/raytolfas/src-themes/fluent-icons ]; then
    git clone --depth=1 https://github.com/vinceliuice/Fluent-icon-theme.git /var/lib/raytolfas/src-themes/fluent-icons
fi
bash /var/lib/raytolfas/src-themes/fluent-icons/install.sh -d "${ROOTFS}/usr/share/icons"

echo "[plasma6] Installed versions:"
chroot "${ROOTFS}" dpkg-query -W plasma-desktop kwin-wayland aurorae plasma-mobile calamares sddm libqt6core6t64 python3-pyqt6 dolphin konsole
echo "[plasma6] Wayland sessions:"
ls -la "${ROOTFS}/usr/share/wayland-sessions/"
echo "[plasma6] Upgrade completed successfully!"
