#!/usr/bin/env bash
set -euo pipefail

ROOTFS="/var/lib/raytolfas/plasma-rootfs"

echo "[sync] Updating os-release..."
cat << 'EOF' > "${ROOTFS}/etc/os-release"
NAME="Raytolfas OS"
PRETTY_NAME="Raytolfas OS D1 (v26.10.0)"
ID=raytolfas
ID_LIKE="ubuntu debian"
VERSION="v26.10.0"
VERSION_ID="26.10.0"
VERSION_CODENAME="noble"
HOME_URL="https://raytolfas.com"
EOF
cp -f "${ROOTFS}/etc/os-release" "${ROOTFS}/usr/lib/os-release" 2>/dev/null || true

echo 'Raytolfas OS D1 (v26.10.0) \n \l' > "${ROOTFS}/etc/issue"
echo 'Raytolfas OS D1 (v26.10.0)' > "${ROOTFS}/etc/issue.net"

echo "[sync] Setting hostname to d1-pc..."
echo "d1-pc" > "${ROOTFS}/etc/hostname"
sed -i "s/raytolfas-pc/d1-pc/g" "${ROOTFS}/etc/hosts" 2>/dev/null || true

echo "[sync] Updating Calamares branding..."
if [ -f "${ROOTFS}/etc/calamares/branding/raytolfas/branding.desc" ]; then
    sed -i "s/v26.09.0/v26.10.0/g" "${ROOTFS}/etc/calamares/branding/raytolfas/branding.desc"
    sed -i "s/D1 Alpha/v26.10.0/g" "${ROOTFS}/etc/calamares/branding/raytolfas/branding.desc"
    sed -i "s/Raytolfas OS D1 Alpha/Raytolfas OS D1/g" "${ROOTFS}/etc/calamares/branding/raytolfas/branding.desc"
fi

echo "[sync] Updating SDDM autologin..."
cat << 'EOF' > "${ROOTFS}/etc/sddm.conf.d/autologin.conf"
[Autologin]
User=admin
Session=plasmawayland
Relogin=false

[Theme]
Current=Fluent
CursorTheme=breeze_cursors
EOF

echo "[sync] Updating environment..."
cat << 'EOF' > "${ROOTFS}/etc/environment"
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
KWIN_DRM_USE_MODIFIERS=0
QT_QPA_PLATFORM="wayland;xcb"
EOF

cat << 'EOF' > "${ROOTFS}/etc/profile.d/kwin-env.sh"
export KWIN_DRM_USE_MODIFIERS=0
EOF
chmod 0644 "${ROOTFS}/etc/profile.d/kwin-env.sh"

echo "[sync] Updating SDDM theme..."
if [ -f "${ROOTFS}/usr/share/sddm/themes/Fluent/Main.qml" ]; then
    sed -i "s/Raytolfas OS D1 Alpha/Raytolfas OS D1/g" "${ROOTFS}/usr/share/sddm/themes/Fluent/Main.qml"
fi

echo "[sync] Updating Plymouth..."
if [ -f "${ROOTFS}/usr/share/plymouth/themes/raytolfas/raytolfas.script" ]; then
    sed -i "s/Raytolfas OS D1 Alpha/Raytolfas OS D1/g" "${ROOTFS}/usr/share/plymouth/themes/raytolfas/raytolfas.script"
fi
if [ -f "${ROOTFS}/usr/share/plymouth/themes/raytolfas/raytolfas.plymouth" ]; then
    sed -i "s/Raytolfas OS D1 Alpha/Raytolfas OS D1/g" "${ROOTFS}/usr/share/plymouth/themes/raytolfas/raytolfas.plymouth"
fi

echo "[sync] Syncing apps..."
mkdir -p "${ROOTFS}/usr/share/raytolfas/control-center"
mkdir -p "${ROOTFS}/usr/share/raytolfas/welcome"
cp -a apps/control-center/. "${ROOTFS}/usr/share/raytolfas/control-center/"
cp -a apps/welcome/. "${ROOTFS}/usr/share/raytolfas/welcome/"
chmod +x "${ROOTFS}/usr/share/raytolfas/control-center/main.py"
chmod +x "${ROOTFS}/usr/share/raytolfas/welcome/main.py"

echo "[sync] Syncing Polkit rules..."
mkdir -p "${ROOTFS}/etc/polkit-1/rules.d"
rm -f "${ROOTFS}/etc/polkit-1/rules.d/"*
cp -f config/polkit/40-raytolfas.rules "${ROOTFS}/etc/polkit-1/rules.d/40-raytolfas.rules"
chown -R root:polkitd "${ROOTFS}/etc/polkit-1/rules.d"
chmod 755 "${ROOTFS}/etc/polkit-1/rules.d"
chmod 644 "${ROOTFS}/etc/polkit-1/rules.d/40-raytolfas.rules"

echo "[sync] Syncing systemd logind power config..."
mkdir -p "${ROOTFS}/etc/systemd/logind.conf.d"
if [ -f config/systemd/logind.conf.d/40-power.conf ]; then
    cp -f config/systemd/logind.conf.d/40-power.conf "${ROOTFS}/etc/systemd/logind.conf.d/40-power.conf"
fi

echo "[sync] Syncing KDE power and session settings..."
mkdir -p "${ROOTFS}/etc/xdg" "${ROOTFS}/etc/skel/.config" "${ROOTFS}/home/admin/.config"
cat << 'KSMSERVERRC' | tee "${ROOTFS}/etc/skel/.config/ksmserverrc" "${ROOTFS}/home/admin/.config/ksmserverrc" "${ROOTFS}/etc/xdg/ksmserverrc" > /dev/null
[General]
confirmLogout=false
loginMode=default
shutdownType=2
KSMSERVERRC

cat << 'POWERRC' | tee "${ROOTFS}/etc/skel/.config/powermanagementprofilesrc" "${ROOTFS}/home/admin/.config/powermanagementprofilesrc" "${ROOTFS}/etc/xdg/powermanagementprofilesrc" > /dev/null
[AC][HandleButtonEvents]
powerButtonAction=1

[Battery][HandleButtonEvents]
powerButtonAction=1

[LowBattery][HandleButtonEvents]
powerButtonAction=1
POWERRC
chown -R 1000:1000 "${ROOTFS}/home/admin/.config/ksmserverrc" "${ROOTFS}/home/admin/.config/powermanagementprofilesrc" 2>/dev/null || true

# Ensure look-and-feel components exist in themes
for t in com.github.vinceliuice.Fluent-round-dark org.raytolfas.desktop org.raytolfas.light; do
    target="${ROOTFS}/usr/share/plasma/look-and-feel/${t}/contents"
    if [ -d "${target}" ]; then
        for comp in logout lockscreen systemdialog components; do
            if [ -d "${ROOTFS}/usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents/${comp}" ] && [ ! -d "${target}/${comp}" ]; then
                cp -r "${ROOTFS}/usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents/${comp}" "${target}/"
            fi
        done
    fi
done

echo "[sync] Syncing Calamares modules..."
mkdir -p "${ROOTFS}/etc/calamares/modules"
if [ -d "config/calamares" ]; then
    for f in config/calamares/*.conf; do
        if [ -f "$f" ]; then
            fname=$(basename "$f")
            if [ "$fname" = "settings.conf" ]; then
                cp -f "$f" "${ROOTFS}/etc/calamares/settings.conf"
            else
                cp -f "$f" "${ROOTFS}/etc/calamares/modules/$fname"
            fi
        fi
    done
fi

echo "[sync] Adding Install Raytolfas OS to desktop..."
mkdir -p "${ROOTFS}/etc/skel/Desktop"
mkdir -p "${ROOTFS}/home/admin/Desktop"
cp -f "${ROOTFS}/usr/share/applications/calamares.desktop" "${ROOTFS}/etc/skel/Desktop/calamares.desktop"
cp -f "${ROOTFS}/usr/share/applications/calamares.desktop" "${ROOTFS}/home/admin/Desktop/calamares.desktop"
chmod 0755 "${ROOTFS}/etc/skel/Desktop/calamares.desktop"
chmod 0755 "${ROOTFS}/home/admin/Desktop/calamares.desktop"
chown 1000:1000 "${ROOTFS}/home/admin/Desktop/calamares.desktop" 2>/dev/null || true

echo "[sync] Syncing kernel and initramfs to rootfs /boot..."
mkdir -p "${ROOTFS}/boot"
if [ -f "build/kernel/arch/x86/boot/bzImage" ]; then
    cp -f "build/kernel/arch/x86/boot/bzImage" "${ROOTFS}/boot/vmlinuz-7.1.0-rc4"
fi
if [ -f "build/kernel/.config" ]; then
    cp -f "build/kernel/.config" "${ROOTFS}/boot/config-7.1.0-rc4"
fi
ln -sf vmlinuz-7.1.0-rc4 "${ROOTFS}/boot/vmlinuz"
ln -sf initrd.img-7.1.0-rc4 "${ROOTFS}/boot/initrd.img"
ln -sf boot/vmlinuz-7.1.0-rc4 "${ROOTFS}/vmlinuz"
ln -sf boot/initrd.img-7.1.0-rc4 "${ROOTFS}/initrd.img"

echo "[sync] Syncing udisks2 mount options..."
mkdir -p "${ROOTFS}/etc/udisks2"
cp -f config/udisks2/mount_options.conf "${ROOTFS}/etc/udisks2/mount_options.conf"

echo "[sync] Applying Waydroid network patch..."
WAYDROID_NET="${ROOTFS}/usr/lib/waydroid/data/scripts/waydroid-net.sh"
if [ -f "$WAYDROID_NET" ]; then
    sed -i 's/LXC_USE_NFT="false"/LXC_USE_NFT="true"/g' "$WAYDROID_NET"
    sed -i 's/command -v iptables-legacy/command -v iptables-nft/g' "$WAYDROID_NET"
    sed -i 's/command -v ip6tables-legacy/command -v ip6tables-nft/g' "$WAYDROID_NET"
    sed -i 's/set -e/set +e/g' "$WAYDROID_NET"
    sed -i 's/FAILED=1/FAILED=0/g' "$WAYDROID_NET"
fi

echo "[sync] Syncing tools and desktop entries..."
cp -f scripts/tools/raytolfas-proton "${ROOTFS}/usr/local/bin/raytolfas-proton"
cp -f scripts/tools/raytolfas-android "${ROOTFS}/usr/local/bin/raytolfas-android"
cp -f scripts/tools/raytolfas-apk-install "${ROOTFS}/usr/local/bin/raytolfas-apk-install"
chmod 0755 "${ROOTFS}/usr/local/bin/raytolfas-proton"
chmod 0755 "${ROOTFS}/usr/local/bin/raytolfas-android"
chmod 0755 "${ROOTFS}/usr/local/bin/raytolfas-apk-install"

cat << 'WINEDESK' > "${ROOTFS}/usr/share/applications/raytolfas-wine.desktop"
[Desktop Entry]
Type=Application
Name=Run Windows Program (Proton-GE)
Comment=Run Windows .exe applications with Proton-GE compatibility layer
Exec=raytolfas-proton %f
Icon=wine
NoDisplay=false
MimeType=application/x-ms-dos-executable;application/x-msdownload;application/x-dosexec;application/vnd.microsoft.portable-executable;
Categories=System;Emulator;
WINEDESK

cat << 'WAYDROIDDESK' > "${ROOTFS}/usr/share/applications/raytolfas-android.desktop"
[Desktop Entry]
Type=Application
Name=Android Subsystem (Waydroid)
Comment=Launch Android apps on Wayland
Exec=raytolfas-android
Icon=android-studio
Terminal=false
Categories=System;Emulator;
WAYDROIDDESK

cat << 'APKDESK' > "${ROOTFS}/usr/share/applications/raytolfas-apk.desktop"
[Desktop Entry]
Type=Application
Name=Install Android App (Waydroid)
Comment=Install .apk files into Waydroid Android container
Exec=raytolfas-apk-install %f
Icon=android-studio
NoDisplay=false
MimeType=application/vnd.android.package-archive;
Categories=System;Emulator;
APKDESK

echo "[sync] Updating mimeinfo cache..."
if which update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${ROOTFS}/usr/share/applications" 2>/dev/null || true
fi

echo "[sync] Completed successfully!"
