#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
PKG_ROOT="/tmp/raytolfas-patch-pkg"
OUTPUT_DIR="${REPO_ROOT}/build/patches"

mkdir -p "${OUTPUT_DIR}"
rm -rf "${PKG_ROOT}"
mkdir -p "${PKG_ROOT}/DEBIAN"
mkdir -p "${PKG_ROOT}/usr/bin"
mkdir -p "${PKG_ROOT}/usr/lib/x86_64-linux-gnu"
mkdir -p "${PKG_ROOT}/usr/local/bin"
mkdir -p "${PKG_ROOT}/usr/local/lib"
mkdir -p "${PKG_ROOT}/usr/share/raytolfas/control-center"
mkdir -p "${PKG_ROOT}/usr/share/mime/packages"
mkdir -p "${PKG_ROOT}/usr/share/applications"
mkdir -p "${PKG_ROOT}/etc/binfmt.d"
mkdir -p "${PKG_ROOT}/etc/sysctl.d"
mkdir -p "${PKG_ROOT}/etc/security/limits.d"
mkdir -p "${PKG_ROOT}/etc/pipewire/pipewire.conf.d"
mkdir -p "${PKG_ROOT}/etc/udev/hwdb.d"
mkdir -p "${PKG_ROOT}/etc/udisks2"
mkdir -p "${PKG_ROOT}/etc/xdg"
mkdir -p "${PKG_ROOT}/etc/skel/.config/MangoHud"
mkdir -p "${PKG_ROOT}/usr/share/plasma/look-and-feel/org.raytolfas.desktop/contents/layouts"

cat << 'EOF' > "${PKG_ROOT}/DEBIAN/control"
Package: raytolfas-patch-v26.10.2
Version: 26.10.2-6
Section: misc
Priority: optional
Architecture: amd64
Maintainer: Raytolfas <mixit@raytolfas.com>
Replaces: raytolfas-patch-v26.10.1, raytolfas-patch-v26.10.0, raytolfas-patch
Breaks: raytolfas-patch-v26.10.1, raytolfas-patch-v26.10.0, raytolfas-patch
Provides: raytolfas-patch
Recommends: kde-spectacle, vokoscreen-ng, gstreamer1.0-vaapi, mangohud, gamemode, power-profiles-daemon, nano, python3-evdev, libinput-tools, linux-image-generic, linux-headers-generic, plasma-mobile, vkbasalt, goverlay, zram-tools
Description: Raytolfas OS D1 v26.10.2 Hotfix Patch
 System optimization, power profiles, in-app updater,
 RayQuiro .rqb runtime, Plasma Mobile support, and mouse navigation.
EOF

cat << 'EOF' > "${PKG_ROOT}/DEBIAN/postinst"
#!/bin/sh

systemd-hwdb update 2>/dev/null || true
udevadm trigger 2>/dev/null || true
sysctl --system 2>/dev/null || true

sed -i '/KWIN_DRM_USE_MODIFIERS/d' /etc/environment 2>/dev/null || true
sed -i '/MESA_VK_WSI_PRESENT_MODE/d' /etc/environment 2>/dev/null || true
sed -i '/RADV_PERFTEST/d' /etc/environment 2>/dev/null || true
rm -f /etc/profile.d/kwin-env.sh 2>/dev/null || true

GENERIC_VMLINUZ="$(ls -1t /boot/vmlinuz-*-generic 2>/dev/null | head -n 1 || true)"
if [ -n "$GENERIC_VMLINUZ" ] && [ -f "$GENERIC_VMLINUZ" ]; then
    GENERIC_NAME="$(basename "$GENERIC_VMLINUZ")"
    VERSION_SUFFIX="${GENERIC_NAME#vmlinuz-}"
    ln -sf "$GENERIC_NAME" /boot/vmlinuz
    ln -sf "boot/$GENERIC_NAME" /vmlinuz 2>/dev/null || true
    if [ -f "/boot/initrd.img-$VERSION_SUFFIX" ]; then
        ln -sf "initrd.img-$VERSION_SUFFIX" /boot/initrd.img
        ln -sf "boot/initrd.img-$VERSION_SUFFIX" /initrd.img 2>/dev/null || true
    fi
fi

kwriteconfig5 --file /etc/xdg/kwinrc --group "org.kde.kdecoration2" --key "library" "org.kde.kwin.aurorae" 2>/dev/null || true
kwriteconfig5 --file /etc/xdg/kwinrc --group "org.kde.kdecoration2" --key "theme" "__aurorae__svg__Fluent-round-dark" 2>/dev/null || true
kwriteconfig5 --file /etc/xdg/kwinrc --group "org.kde.kdecoration2" --key "ButtonsOnRight" "IAX" 2>/dev/null || true
kwriteconfig5 --file /etc/xdg/kwinrc --group "Wayland" --key "AllowTearing" "true" 2>/dev/null || true
kwriteconfig5 --file /etc/xdg/kwinrc --group "Plugins" --key "magiclampEnabled" "true" 2>/dev/null || true
kwriteconfig5 --file /etc/xdg/kwinrc --group "Plugins" --key "scaleEnabled" "true" 2>/dev/null || true
kwriteconfig5 --file /etc/xdg/kwinrc --group "Plugins" --key "blurEnabled" "true" 2>/dev/null || true
kwriteconfig5 --file /etc/xdg/kwinrc --group "Plugins" --key "contrastEnabled" "true" 2>/dev/null || true
kwriteconfig5 --file /etc/xdg/kwinrc --group "Plugins" --key "translucencyEnabled" "true" 2>/dev/null || true
kwriteconfig5 --file /etc/xdg/kwinrc --group "Effect-blur" --key "BlurStrength" "9" 2>/dev/null || true
kwriteconfig5 --file /etc/xdg/kwinrc --group "Effect-blur" --key "NoiseStrength" "0" 2>/dev/null || true
kwriteconfig5 --file /etc/xdg/kwinrc --group "Effect-magiclamp" --key "AnimationDuration" "250" 2>/dev/null || true

for u in /etc/skel /home/*; do
    if [ -d "$u/.config" ]; then
        if [ ! -f "$u/.config/kwinrc" ]; then
            cp -f /etc/xdg/kwinrc "$u/.config/kwinrc" 2>/dev/null || true
        else
            kwriteconfig5 --file "$u/.config/kwinrc" --group "org.kde.kdecoration2" --key "library" "org.kde.kwin.aurorae" 2>/dev/null || true
            kwriteconfig5 --file "$u/.config/kwinrc" --group "org.kde.kdecoration2" --key "theme" "__aurorae__svg__Fluent-round-dark" 2>/dev/null || true
            kwriteconfig5 --file "$u/.config/kwinrc" --group "org.kde.kdecoration2" --key "ButtonsOnRight" "IAX" 2>/dev/null || true
            kwriteconfig5 --file "$u/.config/kwinrc" --group "Wayland" --key "AllowTearing" "true" 2>/dev/null || true
            kwriteconfig5 --file "$u/.config/kwinrc" --group "Plugins" --key "magiclampEnabled" "true" 2>/dev/null || true
            kwriteconfig5 --file "$u/.config/kwinrc" --group "Plugins" --key "scaleEnabled" "true" 2>/dev/null || true
            kwriteconfig5 --file "$u/.config/kwinrc" --group "Plugins" --key "blurEnabled" "true" 2>/dev/null || true
            kwriteconfig5 --file "$u/.config/kwinrc" --group "Plugins" --key "contrastEnabled" "true" 2>/dev/null || true
            kwriteconfig5 --file "$u/.config/kwinrc" --group "Plugins" --key "translucencyEnabled" "true" 2>/dev/null || true
            kwriteconfig5 --file "$u/.config/kwinrc" --group "Effect-blur" --key "BlurStrength" "9" 2>/dev/null || true
            kwriteconfig5 --file "$u/.config/kwinrc" --group "Effect-blur" --key "NoiseStrength" "0" 2>/dev/null || true
            kwriteconfig5 --file "$u/.config/kwinrc" --group "Effect-magiclamp" --key "AnimationDuration" "250" 2>/dev/null || true
        fi
        rm -f "$u/.config/plasmashellrc" 2>/dev/null || true
        if [ -f "$u/.config/plasma-org.kde.plasma.desktop-appletsrc" ]; then
            sed -i 's/floating=1/floating=0/g' "$u/.config/plasma-org.kde.plasma.desktop-appletsrc" 2>/dev/null || true
        fi
        if [ -d "$u" ] && [ "$u" != "/etc/skel" ]; then
            chown $(stat -c '%u:%g' "$u") "$u/.config/kwinrc" 2>/dev/null || true
        fi
    fi
done

rm -f /etc/xdg/plasmashellrc 2>/dev/null || true

PANEL_QML="/usr/share/plasma/shells/org.kde.plasma.desktop/contents/views/Panel.qml"
if [ -f "$PANEL_QML" ]; then
    sed -i 's/property bool floating: containment .*/property bool floating: panel.floating/g' "$PANEL_QML" 2>/dev/null || true
fi

if [ -f /etc/MangoHud.conf ]; then
    for u in /etc/skel /home/*; do
        if [ -d "$u" ]; then
            mkdir -p "$u/.config/MangoHud" 2>/dev/null || true
            cp -f /etc/MangoHud.conf "$u/.config/MangoHud/MangoHud.conf" 2>/dev/null || true
            if [ "$u" != "/etc/skel" ]; then
                chown -R $(stat -c '%u:%g' "$u") "$u/.config/MangoHud" 2>/dev/null || true
            fi
        fi
    done
fi

if [ -f /etc/xdg/kglobalshortcutsrc ]; then
    for u in /home/*; do
        if [ -d "$u/.config" ]; then
            cp -f /etc/xdg/kglobalshortcutsrc "$u/.config/kglobalshortcutsrc" 2>/dev/null || true
            chown $(stat -c '%u:%g' "$u") "$u/.config/kglobalshortcutsrc" 2>/dev/null || true
        fi
    done
fi

LAYOUT_SRC="/usr/share/plasma/look-and-feel/org.raytolfas.desktop/contents/layouts/org.kde.plasma.desktop-layout.js"
if [ -f "$LAYOUT_SRC" ]; then
    mkdir -p /usr/share/plasma/look-and-feel/com.github.vinceliuice.Fluent-round-dark/contents/layouts
    mkdir -p /usr/share/plasma/shells/org.kde.plasma.desktop/contents
    mkdir -p /usr/share/plasma/layout-templates/org.kde.plasma.desktop.defaultPanel/contents
    cp -f "$LAYOUT_SRC" /usr/share/plasma/look-and-feel/com.github.vinceliuice.Fluent-round-dark/contents/layouts/org.kde.plasma.desktop-layout.js 2>/dev/null || true
    cp -f "$LAYOUT_SRC" /usr/share/plasma/shells/org.kde.plasma.desktop/contents/layout.js 2>/dev/null || true
    cp -f "$LAYOUT_SRC" /usr/share/plasma/layout-templates/org.kde.plasma.desktop.defaultPanel/contents/layout.js 2>/dev/null || true
fi

/usr/local/bin/raytolfas-waydroid-net-fix 2>/dev/null || true

systemctl enable --now power-profiles-daemon 2>/dev/null || true
powerprofilesctl set balanced 2>/dev/null || true

timedatectl set-local-rtc 1 --adjust-system-clock 2>/dev/null || true
systemctl restart udisks2 2>/dev/null || true

cat << 'ZRAM_EOF' > /etc/default/zramswap
ALGO=zstd
PERCENT=100
PRIORITY=100
ZRAM_EOF
chmod 0644 /etc/default/zramswap 2>/dev/null || true
systemctl enable --now zramswap 2>/dev/null || true
systemctl restart zramswap 2>/dev/null || true

mount -t binfmt_misc none /proc/sys/fs/binfmt_misc 2>/dev/null || true
if [ -d /proc/sys/fs/binfmt_misc ]; then
    echo ':rqb:M::RQB1::/usr/bin/rqio:P' > /proc/sys/fs/binfmt_misc/register 2>/dev/null || true
fi
systemctl restart systemd-binfmt 2>/dev/null || true

update-mime-database /usr/share/mime 2>/dev/null || true
update-desktop-database /usr/share/applications 2>/dev/null || true

chmod 0755 /usr/bin/rqio 2>/dev/null || true
chmod 0755 /usr/lib/rqio_core.so /usr/lib/x86_64-linux-gnu/rqio_core.so /usr/local/lib/rqio_core.so 2>/dev/null || true
chmod 0755 /usr/local/bin/raytolfas-rqb-runner /usr/bin/raytolfas-rqb-runner 2>/dev/null || true
chmod 0755 /usr/local/bin/prime-run /usr/bin/prime-run 2>/dev/null || true
rm -f /usr/local/bin/raytolfas-nvidia-setup /usr/bin/raytolfas-nvidia-setup 2>/dev/null || true
ldconfig 2>/dev/null || true

exit 0
EOF
chmod 0755 "${PKG_ROOT}/DEBIAN/postinst"
chmod 0755 "${PKG_ROOT}/DEBIAN"

if [ -f "${REPO_ROOT}/assets/rqio/rqio" ]; then
    cp -f "${REPO_ROOT}/assets/rqio/rqio" "${PKG_ROOT}/usr/bin/rqio"
    chmod 0755 "${PKG_ROOT}/usr/bin/rqio"
fi
if [ -f "${REPO_ROOT}/assets/rqio/rqio_core.so" ]; then
    cp -f "${REPO_ROOT}/assets/rqio/rqio_core.so" "${PKG_ROOT}/usr/lib/rqio_core.so"
    cp -f "${REPO_ROOT}/assets/rqio/rqio_core.so" "${PKG_ROOT}/usr/lib/x86_64-linux-gnu/rqio_core.so"
    cp -f "${REPO_ROOT}/assets/rqio/rqio_core.so" "${PKG_ROOT}/usr/local/lib/rqio_core.so"
    chmod 0755 "${PKG_ROOT}/usr/lib/rqio_core.so" "${PKG_ROOT}/usr/lib/x86_64-linux-gnu/rqio_core.so" "${PKG_ROOT}/usr/local/lib/rqio_core.so"
fi

if [ -f "${REPO_ROOT}/config/binfmt/rqb.conf" ]; then
    cp -f "${REPO_ROOT}/config/binfmt/rqb.conf" "${PKG_ROOT}/etc/binfmt.d/rqb.conf"
    chmod 0644 "${PKG_ROOT}/etc/binfmt.d/rqb.conf"
fi
if [ -f "${REPO_ROOT}/config/mime/rqb.xml" ]; then
    cp -f "${REPO_ROOT}/config/mime/rqb.xml" "${PKG_ROOT}/usr/share/mime/packages/rqb.xml"
    chmod 0644 "${PKG_ROOT}/usr/share/mime/packages/rqb.xml"
fi
if [ -f "${REPO_ROOT}/config/applications/raytolfas-rqb.desktop" ]; then
    cp -f "${REPO_ROOT}/config/applications/raytolfas-rqb.desktop" "${PKG_ROOT}/usr/share/applications/raytolfas-rqb.desktop"
    chmod 0644 "${PKG_ROOT}/usr/share/applications/raytolfas-rqb.desktop"
fi

cat << 'WINEDESK' > "${PKG_ROOT}/usr/share/applications/raytolfas-wine.desktop"
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
chmod 0644 "${PKG_ROOT}/usr/share/applications/raytolfas-wine.desktop"

cp -f "${REPO_ROOT}/scripts/tools/raytolfas-proton" "${PKG_ROOT}/usr/local/bin/raytolfas-proton"
cp -f "${REPO_ROOT}/scripts/tools/raytolfas-proton" "${PKG_ROOT}/usr/bin/raytolfas-proton"
cp -f "${REPO_ROOT}/scripts/tools/raytolfas-android" "${PKG_ROOT}/usr/local/bin/raytolfas-android"
cp -f "${REPO_ROOT}/scripts/tools/raytolfas-apk-install" "${PKG_ROOT}/usr/local/bin/raytolfas-apk-install"
cp -f "${REPO_ROOT}/scripts/tools/raytolfas-waydroid-setup" "${PKG_ROOT}/usr/local/bin/raytolfas-waydroid-setup"
cp -f "${REPO_ROOT}/scripts/tools/raytolfas-waydroid-net-fix" "${PKG_ROOT}/usr/local/bin/raytolfas-waydroid-net-fix"
cp -f "${REPO_ROOT}/scripts/tools/raytolfas-mobile-test" "${PKG_ROOT}/usr/local/bin/raytolfas-mobile-test"
cp -f "${REPO_ROOT}/scripts/tools/prime-run" "${PKG_ROOT}/usr/local/bin/prime-run"
cp -f "${REPO_ROOT}/scripts/tools/prime-run" "${PKG_ROOT}/usr/bin/prime-run"
cp -f "${REPO_ROOT}/scripts/tools/raytolfas-rqb-runner" "${PKG_ROOT}/usr/local/bin/raytolfas-rqb-runner"
cp -f "${REPO_ROOT}/scripts/tools/raytolfas-rqb-runner" "${PKG_ROOT}/usr/bin/raytolfas-rqb-runner"
if [ -f "${REPO_ROOT}/scripts/tools/raytolfas-upgrade-iso" ]; then
    cp -f "${REPO_ROOT}/scripts/tools/raytolfas-upgrade-iso" "${PKG_ROOT}/usr/local/bin/raytolfas-upgrade-iso"
    cp -f "${REPO_ROOT}/scripts/tools/raytolfas-upgrade-iso" "${PKG_ROOT}/usr/bin/raytolfas-upgrade-iso"
fi

chmod 0755 "${PKG_ROOT}/usr/local/bin/raytolfas-proton" "${PKG_ROOT}/usr/bin/raytolfas-proton"
chmod 0755 "${PKG_ROOT}/usr/local/bin/raytolfas-android"
chmod 0755 "${PKG_ROOT}/usr/local/bin/raytolfas-apk-install"
chmod 0755 "${PKG_ROOT}/usr/local/bin/raytolfas-waydroid-setup"
chmod 0755 "${PKG_ROOT}/usr/local/bin/raytolfas-waydroid-net-fix"
chmod 0755 "${PKG_ROOT}/usr/local/bin/raytolfas-mobile-test"
chmod 0755 "${PKG_ROOT}/usr/local/bin/prime-run" "${PKG_ROOT}/usr/bin/prime-run"
chmod 0755 "${PKG_ROOT}/usr/local/bin/raytolfas-rqb-runner" "${PKG_ROOT}/usr/bin/raytolfas-rqb-runner"
if [ -f "${PKG_ROOT}/usr/local/bin/raytolfas-upgrade-iso" ]; then
    chmod 0755 "${PKG_ROOT}/usr/local/bin/raytolfas-upgrade-iso" "${PKG_ROOT}/usr/bin/raytolfas-upgrade-iso"
fi

cp -f "${REPO_ROOT}/apps/control-center/main.py" "${PKG_ROOT}/usr/share/raytolfas/control-center/main.py"
cp -f "${REPO_ROOT}/apps/control-center/ControlCenter.qml" "${PKG_ROOT}/usr/share/raytolfas/control-center/ControlCenter.qml"
chmod 0755 "${PKG_ROOT}/usr/share/raytolfas/control-center/main.py"
chmod 0644 "${PKG_ROOT}/usr/share/raytolfas/control-center/ControlCenter.qml"

cp -f "${REPO_ROOT}/config/gaming/gamemode.ini" "${PKG_ROOT}/etc/gamemode.ini"
cp -f "${REPO_ROOT}/config/sysctl/99-raytolfas-performance.conf" "${PKG_ROOT}/etc/sysctl.d/99-raytolfas-performance.conf"
cp -f "${REPO_ROOT}/config/limits/99-raytolfas-gaming.conf" "${PKG_ROOT}/etc/security/limits.d/99-raytolfas-gaming.conf"
cp -f "${REPO_ROOT}/config/pipewire/10-lowlatency.conf" "${PKG_ROOT}/etc/pipewire/pipewire.conf.d/10-lowlatency.conf"
cp -f "${REPO_ROOT}/config/udev/70-mouse-keys.hwdb" "${PKG_ROOT}/etc/udev/hwdb.d/70-mouse-keys.hwdb"
cp -f "${REPO_ROOT}/config/kde/kglobalshortcutsrc" "${PKG_ROOT}/etc/xdg/kglobalshortcutsrc"
cp -f "${REPO_ROOT}/config/udisks2/mount_options.conf" "${PKG_ROOT}/etc/udisks2/mount_options.conf"
cp -f "${REPO_ROOT}/config/mangohud/MangoHud.conf" "${PKG_ROOT}/etc/MangoHud.conf"
cp -f "${REPO_ROOT}/config/mangohud/MangoHud.conf" "${PKG_ROOT}/etc/skel/.config/MangoHud/MangoHud.conf"

chmod 0644 "${PKG_ROOT}/etc/gamemode.ini"
chmod 0644 "${PKG_ROOT}/etc/sysctl.d/99-raytolfas-performance.conf"
chmod 0644 "${PKG_ROOT}/etc/security/limits.d/99-raytolfas-gaming.conf"
chmod 0644 "${PKG_ROOT}/etc/pipewire/pipewire.conf.d/10-lowlatency.conf"
chmod 0644 "${PKG_ROOT}/etc/udev/hwdb.d/70-mouse-keys.hwdb"
chmod 0644 "${PKG_ROOT}/etc/xdg/kglobalshortcutsrc"
chmod 0644 "${PKG_ROOT}/etc/udisks2/mount_options.conf"
chmod 0644 "${PKG_ROOT}/etc/MangoHud.conf"
chmod 0644 "${PKG_ROOT}/etc/skel/.config/MangoHud/MangoHud.conf"

if [ -f "${REPO_ROOT}/config/kde/Panel.qml" ]; then
    mkdir -p "${PKG_ROOT}/usr/share/plasma/shells/org.kde.plasma.desktop/contents/views"
    cp -f "${REPO_ROOT}/config/kde/Panel.qml" "${PKG_ROOT}/usr/share/plasma/shells/org.kde.plasma.desktop/contents/views/Panel.qml"
    chmod 0644 "${PKG_ROOT}/usr/share/plasma/shells/org.kde.plasma.desktop/contents/views/Panel.qml"
fi
if [ -f "${REPO_ROOT}/config/kde/org.kde.plasma.desktop-layout.js" ]; then
    mkdir -p "${PKG_ROOT}/usr/share/plasma/look-and-feel/org.raytolfas.desktop/contents/layouts"
    mkdir -p "${PKG_ROOT}/usr/share/plasma/look-and-feel/com.github.vinceliuice.Fluent-round-dark/contents/layouts"
    mkdir -p "${PKG_ROOT}/usr/share/plasma/shells/org.kde.plasma.desktop/contents"
    mkdir -p "${PKG_ROOT}/usr/share/plasma/layout-templates/org.kde.plasma.desktop.defaultPanel/contents"
    cp -f "${REPO_ROOT}/config/kde/org.kde.plasma.desktop-layout.js" "${PKG_ROOT}/usr/share/plasma/look-and-feel/org.raytolfas.desktop/contents/layouts/org.kde.plasma.desktop-layout.js"
    cp -f "${REPO_ROOT}/config/kde/org.kde.plasma.desktop-layout.js" "${PKG_ROOT}/usr/share/plasma/look-and-feel/com.github.vinceliuice.Fluent-round-dark/contents/layouts/org.kde.plasma.desktop-layout.js"
    cp -f "${REPO_ROOT}/config/kde/org.kde.plasma.desktop-layout.js" "${PKG_ROOT}/usr/share/plasma/shells/org.kde.plasma.desktop/contents/layout.js"
    cp -f "${REPO_ROOT}/config/kde/org.kde.plasma.desktop-layout.js" "${PKG_ROOT}/usr/share/plasma/layout-templates/org.kde.plasma.desktop.defaultPanel/contents/layout.js"
    chmod 0644 "${PKG_ROOT}/usr/share/plasma/look-and-feel/org.raytolfas.desktop/contents/layouts/org.kde.plasma.desktop-layout.js"
    chmod 0644 "${PKG_ROOT}/usr/share/plasma/look-and-feel/com.github.vinceliuice.Fluent-round-dark/contents/layouts/org.kde.plasma.desktop-layout.js"
    chmod 0644 "${PKG_ROOT}/usr/share/plasma/shells/org.kde.plasma.desktop/contents/layout.js"
    chmod 0644 "${PKG_ROOT}/usr/share/plasma/layout-templates/org.kde.plasma.desktop.defaultPanel/contents/layout.js"
fi

find "${PKG_ROOT}" -type d -exec chmod 0755 {} +

dpkg-deb --build --root-owner-group "${PKG_ROOT}" "${OUTPUT_DIR}/raytolfas-patch-v26.10.2_amd64.deb"

echo "[patch] Built successfully: ${OUTPUT_DIR}/raytolfas-patch-v26.10.2_amd64.deb"
