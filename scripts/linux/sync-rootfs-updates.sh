#!/usr/bin/env bash
set -euo pipefail

ROOTFS="/var/lib/raytolfas/plasma-rootfs"

echo "[sync] Updating os-release..."
cat << 'EOF' > "${ROOTFS}/etc/os-release"
NAME="Raytolfas OS"
PRETTY_NAME="Raytolfas OS D1 (v26.10.2)"
ID=raytolfas
ID_LIKE="ubuntu debian"
VERSION="v26.10.2"
VERSION_ID="26.10.2"
VERSION_CODENAME="noble"
HOME_URL="https://os.raytolfas.cc"
EOF
cp -f "${ROOTFS}/etc/os-release" "${ROOTFS}/usr/lib/os-release" 2>/dev/null || true

echo 'Raytolfas OS D1 (v26.10.2) \n \l' > "${ROOTFS}/etc/issue"
echo 'Raytolfas OS D1 (v26.10.2)' > "${ROOTFS}/etc/issue.net"

echo "[sync] Setting hostname to d1-pc..."
echo "d1-pc" > "${ROOTFS}/etc/hostname"
sed -i "s/raytolfas-pc/d1-pc/g" "${ROOTFS}/etc/hosts" 2>/dev/null || true

echo "[sync] Updating Calamares branding..."
if [ -f "${ROOTFS}/etc/calamares/branding/raytolfas/branding.desc" ]; then
    sed -i "s/v26.09.0/v26.10.2/g; s/v26.10.0/v26.10.2/g" "${ROOTFS}/etc/calamares/branding/raytolfas/branding.desc"
    sed -i "s/D1 Alpha/v26.10.2/g" "${ROOTFS}/etc/calamares/branding/raytolfas/branding.desc"
    sed -i "s/Raytolfas OS D1 Alpha/Raytolfas OS D1/g" "${ROOTFS}/etc/calamares/branding/raytolfas/branding.desc"
    sed -i "s|https://raytolfas.com|https://os.raytolfas.cc|g; s|https://raytolfas.org|https://os.raytolfas.cc|g" "${ROOTFS}/etc/calamares/branding/raytolfas/branding.desc"
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
QT_QPA_PLATFORM="wayland;xcb"
EOF
rm -f "${ROOTFS}/etc/profile.d/kwin-env.sh"

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

echo "[sync] Syncing kernel symlinks to official generic kernel in rootfs /boot..."
mkdir -p "${ROOTFS}/boot"
GENERIC_VMLINUZ="$(ls -1t "${ROOTFS}/boot/vmlinuz-"*-generic 2>/dev/null | head -n 1 || true)"
if [ -n "${GENERIC_VMLINUZ}" ] && [ -f "${GENERIC_VMLINUZ}" ]; then
    GENERIC_NAME="$(basename "${GENERIC_VMLINUZ}")"
    VERSION_SUFFIX="${GENERIC_NAME#vmlinuz-}"
    ln -sf "${GENERIC_NAME}" "${ROOTFS}/boot/vmlinuz"
    ln -sf "boot/${GENERIC_NAME}" "${ROOTFS}/vmlinuz"
    if [ -f "${ROOTFS}/boot/initrd.img-${VERSION_SUFFIX}" ]; then
        ln -sf "initrd.img-${VERSION_SUFFIX}" "${ROOTFS}/boot/initrd.img"
        ln -sf "boot/initrd.img-${VERSION_SUFFIX}" "${ROOTFS}/initrd.img"
    fi
fi

echo "[sync] Cleaning udisks2 mount options..."
rm -f "${ROOTFS}/etc/udisks2/mount_options.conf"

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
cp -f scripts/tools/raytolfas-proton "${ROOTFS}/usr/bin/raytolfas-proton"
cp -f scripts/tools/raytolfas-android "${ROOTFS}/usr/local/bin/raytolfas-android"
cp -f scripts/tools/raytolfas-apk-install "${ROOTFS}/usr/local/bin/raytolfas-apk-install"
if [ -f scripts/tools/raytolfas-waydroid-setup ]; then
    cp -f scripts/tools/raytolfas-waydroid-setup "${ROOTFS}/usr/local/bin/raytolfas-waydroid-setup"
    chmod 0755 "${ROOTFS}/usr/local/bin/raytolfas-waydroid-setup"
fi
if [ -f scripts/tools/raytolfas-waydroid-net-fix ]; then
    cp -f scripts/tools/raytolfas-waydroid-net-fix "${ROOTFS}/usr/local/bin/raytolfas-waydroid-net-fix"
    chmod 0755 "${ROOTFS}/usr/local/bin/raytolfas-waydroid-net-fix"
fi
cp -f scripts/tools/prime-run "${ROOTFS}/usr/local/bin/prime-run"
cp -f scripts/tools/prime-run "${ROOTFS}/usr/bin/prime-run"
cp -f scripts/tools/raytolfas-mobile-test "${ROOTFS}/usr/local/bin/raytolfas-mobile-test"
cp -f scripts/tools/raytolfas-rqb-runner "${ROOTFS}/usr/local/bin/raytolfas-rqb-runner"
cp -f scripts/tools/raytolfas-rqb-runner "${ROOTFS}/usr/bin/raytolfas-rqb-runner"
if [ -f scripts/tools/raytolfas-upgrade-iso ]; then
    cp -f scripts/tools/raytolfas-upgrade-iso "${ROOTFS}/usr/local/bin/raytolfas-upgrade-iso"
    cp -f scripts/tools/raytolfas-upgrade-iso "${ROOTFS}/usr/bin/raytolfas-upgrade-iso"
    chmod 0755 "${ROOTFS}/usr/local/bin/raytolfas-upgrade-iso" "${ROOTFS}/usr/bin/raytolfas-upgrade-iso"
fi
rm -f "${ROOTFS}/usr/local/bin/raytolfas-nvidia-setup" "${ROOTFS}/usr/bin/raytolfas-nvidia-setup"
chmod 0755 "${ROOTFS}/usr/local/bin/raytolfas-proton" "${ROOTFS}/usr/bin/raytolfas-proton"
chmod 0755 "${ROOTFS}/usr/local/bin/raytolfas-android"
chmod 0755 "${ROOTFS}/usr/local/bin/raytolfas-apk-install"
chmod 0755 "${ROOTFS}/usr/local/bin/prime-run" "${ROOTFS}/usr/bin/prime-run"
chmod 0755 "${ROOTFS}/usr/local/bin/raytolfas-mobile-test"
chmod 0755 "${ROOTFS}/usr/local/bin/raytolfas-rqb-runner" "${ROOTFS}/usr/bin/raytolfas-rqb-runner"

echo "[sync] Syncing system optimizations, audio latency and gaming configs..."
mkdir -p "${ROOTFS}/etc/sysctl.d" "${ROOTFS}/etc/security/limits.d" "${ROOTFS}/etc/pipewire/pipewire.conf.d" "${ROOTFS}/etc/udev/hwdb.d"
if [ -f config/sysctl/99-raytolfas-performance.conf ]; then
    cp -f config/sysctl/99-raytolfas-performance.conf "${ROOTFS}/etc/sysctl.d/99-raytolfas-performance.conf"
fi
if [ -f config/limits/99-raytolfas-gaming.conf ]; then
    cp -f config/limits/99-raytolfas-gaming.conf "${ROOTFS}/etc/security/limits.d/99-raytolfas-gaming.conf"
fi
if [ -f config/gaming/gamemode.ini ]; then
    cp -f config/gaming/gamemode.ini "${ROOTFS}/etc/gamemode.ini"
fi
if [ -f config/pipewire/10-lowlatency.conf ]; then
    cp -f config/pipewire/10-lowlatency.conf "${ROOTFS}/etc/pipewire/pipewire.conf.d/10-lowlatency.conf"
fi
if [ -f config/udev/70-mouse-keys.hwdb ]; then
    cp -f config/udev/70-mouse-keys.hwdb "${ROOTFS}/etc/udev/hwdb.d/70-mouse-keys.hwdb"
fi
if [ -f config/kde/kglobalshortcutsrc ]; then
    mkdir -p "${ROOTFS}/etc/xdg" "${ROOTFS}/etc/skel/.config" "${ROOTFS}/home/admin/.config"
    cp -f config/kde/kglobalshortcutsrc "${ROOTFS}/etc/xdg/kglobalshortcutsrc"
    cp -f config/kde/kglobalshortcutsrc "${ROOTFS}/etc/skel/.config/kglobalshortcutsrc"
    cp -f config/kde/kglobalshortcutsrc "${ROOTFS}/home/admin/.config/kglobalshortcutsrc"
    chown -R 1000:1000 "${ROOTFS}/home/admin/.config/kglobalshortcutsrc" 2>/dev/null || true
fi
echo "[sync] Syncing KWin configuration and Wayland tearing settings..."
if [ -f config/kde/kwinrc ]; then
    mkdir -p "${ROOTFS}/etc/xdg" "${ROOTFS}/etc/skel/.config" "${ROOTFS}/home/admin/.config"
    cp -f config/kde/kwinrc "${ROOTFS}/etc/xdg/kwinrc"
    cp -f config/kde/kwinrc "${ROOTFS}/etc/skel/.config/kwinrc"
    cp -f config/kde/kwinrc "${ROOTFS}/home/admin/.config/kwinrc"
    chown -R 1000:1000 "${ROOTFS}/home/admin/.config/kwinrc" 2>/dev/null || true
fi
rm -f "${ROOTFS}/etc/xdg/plasmashellrc" "${ROOTFS}/etc/skel/.config/plasmashellrc" "${ROOTFS}/home/admin/.config/plasmashellrc"
rm -f "${ROOTFS}/home/admin/.config/plasma-org.kde.plasma.desktop-appletsrc" "${ROOTFS}/etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc"

if [ -f config/kde/org.kde.plasma.desktop-layout.js ]; then
    mkdir -p "${ROOTFS}/usr/share/plasma/look-and-feel/org.raytolfas.desktop/contents/layouts"
    mkdir -p "${ROOTFS}/usr/share/plasma/look-and-feel/com.github.vinceliuice.Fluent-round-dark/contents/layouts"
    mkdir -p "${ROOTFS}/usr/share/plasma/shells/org.kde.plasma.desktop/contents"
    mkdir -p "${ROOTFS}/usr/share/plasma/layout-templates/org.kde.plasma.desktop.defaultPanel/contents"
    cp -f config/kde/org.kde.plasma.desktop-layout.js "${ROOTFS}/usr/share/plasma/look-and-feel/org.raytolfas.desktop/contents/layouts/org.kde.plasma.desktop-layout.js"
    cp -f config/kde/org.kde.plasma.desktop-layout.js "${ROOTFS}/usr/share/plasma/look-and-feel/com.github.vinceliuice.Fluent-round-dark/contents/layouts/org.kde.plasma.desktop-layout.js"
    cp -f config/kde/org.kde.plasma.desktop-layout.js "${ROOTFS}/usr/share/plasma/shells/org.kde.plasma.desktop/contents/layout.js"
    cp -f config/kde/org.kde.plasma.desktop-layout.js "${ROOTFS}/usr/share/plasma/layout-templates/org.kde.plasma.desktop.defaultPanel/contents/layout.js"
fi

if [ -f config/kde/Panel.qml ]; then
    cp -f config/kde/Panel.qml "${ROOTFS}/usr/share/plasma/shells/org.kde.plasma.desktop/contents/views/Panel.qml"
    chmod 0644 "${ROOTFS}/usr/share/plasma/shells/org.kde.plasma.desktop/contents/views/Panel.qml"
fi

echo "[sync] Syncing safe udisks2 mount options and MangoHud configuration..."
if [ -f config/udisks2/mount_options.conf ]; then
    mkdir -p "${ROOTFS}/etc/udisks2"
    cp -f config/udisks2/mount_options.conf "${ROOTFS}/etc/udisks2/mount_options.conf"
    chmod 0644 "${ROOTFS}/etc/udisks2/mount_options.conf"
fi
if [ -f config/mangohud/MangoHud.conf ]; then
    mkdir -p "${ROOTFS}/etc/skel/.config/MangoHud" "${ROOTFS}/home/admin/.config/MangoHud"
    cp -f config/mangohud/MangoHud.conf "${ROOTFS}/etc/MangoHud.conf"
    cp -f config/mangohud/MangoHud.conf "${ROOTFS}/etc/skel/.config/MangoHud/MangoHud.conf"
    cp -f config/mangohud/MangoHud.conf "${ROOTFS}/home/admin/.config/MangoHud/MangoHud.conf"
    chmod 0644 "${ROOTFS}/etc/MangoHud.conf"
    chown -R 1000:1000 "${ROOTFS}/home/admin/.config/MangoHud" 2>/dev/null || true
fi
if [ -f config/zram/zramswap ]; then
    mkdir -p "${ROOTFS}/etc/default"
    cp -f config/zram/zramswap "${ROOTFS}/etc/default/zramswap"
    chmod 0644 "${ROOTFS}/etc/default/zramswap"
fi

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

if [ -f assets/rqio/rqio ]; then
    cp -f assets/rqio/rqio "${ROOTFS}/usr/bin/rqio"
    chmod 0755 "${ROOTFS}/usr/bin/rqio"
fi
if [ -f assets/rqio/rqio_core.so ]; then
    mkdir -p "${ROOTFS}/usr/lib/x86_64-linux-gnu" "${ROOTFS}/usr/local/lib"
    rm -f "${ROOTFS}/usr/lib/rqio_core.so" "${ROOTFS}/usr/lib/x86_64-linux-gnu/rqio_core.so" "${ROOTFS}/usr/local/lib/rqio_core.so"
    cp -f assets/rqio/rqio_core.so "${ROOTFS}/usr/lib/rqio_core.so"
    cp -f assets/rqio/rqio_core.so "${ROOTFS}/usr/lib/x86_64-linux-gnu/rqio_core.so"
    cp -f assets/rqio/rqio_core.so "${ROOTFS}/usr/local/lib/rqio_core.so"
    chmod 0755 "${ROOTFS}/usr/lib/rqio_core.so" "${ROOTFS}/usr/lib/x86_64-linux-gnu/rqio_core.so" "${ROOTFS}/usr/local/lib/rqio_core.so"
    chroot "${ROOTFS}" ldconfig 2>/dev/null || true
fi
if [ -f config/binfmt/rqb.conf ]; then
    mkdir -p "${ROOTFS}/etc/binfmt.d"
    cp -f config/binfmt/rqb.conf "${ROOTFS}/etc/binfmt.d/rqb.conf"
fi
if [ -f config/mime/rqb.xml ]; then
    mkdir -p "${ROOTFS}/usr/share/mime/packages"
    cp -f config/mime/rqb.xml "${ROOTFS}/usr/share/mime/packages/rqb.xml"
fi
if [ -f config/applications/raytolfas-rqb.desktop ]; then
    cp -f config/applications/raytolfas-rqb.desktop "${ROOTFS}/usr/share/applications/raytolfas-rqb.desktop"
fi

echo "[sync] Updating mimeinfo cache..."
if which update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${ROOTFS}/usr/share/applications" 2>/dev/null || true
fi
if which update-mime-database >/dev/null 2>&1; then
    update-mime-database "${ROOTFS}/usr/share/mime" 2>/dev/null || true
fi

if [ -d "${ROOTFS}/etc" ]; then
    echo "[sync] Updating hwdb database..."
    chroot "${ROOTFS}" systemd-hwdb update 2>/dev/null || true
    echo "[sync] Checking packages..."
    chroot "${ROOTFS}" /bin/bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y 2>/dev/null || true
        apt-get install -y --no-install-recommends kde-spectacle vokoscreen-ng gstreamer1.0-vaapi mangohud gamemode power-profiles-daemon kdeconnect vkbasalt goverlay nano python3-evdev libinput-tools 2>/dev/null || true
    " 2>/dev/null || true
fi

echo "[sync] Completed successfully!"
