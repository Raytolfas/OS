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
mkdir -p "${PKG_ROOT}/usr/share/fastfetch"
mkdir -p "${PKG_ROOT}/usr/share/pixmaps"
mkdir -p "${PKG_ROOT}/usr/share/icons/hicolor/scalable/apps"
mkdir -p "${PKG_ROOT}/usr/share/icons/hicolor/512x512/apps"
mkdir -p "${PKG_ROOT}/usr/share/mime/packages"
mkdir -p "${PKG_ROOT}/usr/share/applications"
mkdir -p "${PKG_ROOT}/etc/apt/apt.conf.d"
mkdir -p "${PKG_ROOT}/etc/binfmt.d"
mkdir -p "${PKG_ROOT}/etc/sysctl.d"
mkdir -p "${PKG_ROOT}/etc/security/limits.d"
mkdir -p "${PKG_ROOT}/etc/pipewire/pipewire.conf.d"
mkdir -p "${PKG_ROOT}/etc/udev/hwdb.d"
mkdir -p "${PKG_ROOT}/etc/udev/rules.d"
mkdir -p "${PKG_ROOT}/etc/udisks2"
mkdir -p "${PKG_ROOT}/etc/xdg"
mkdir -p "${PKG_ROOT}/etc/calamares/modules"
mkdir -p "${PKG_ROOT}/etc/skel/.config/MangoHud"
mkdir -p "${PKG_ROOT}/usr/share/plasma/look-and-feel/org.raytolfas.desktop/contents/layouts"
mkdir -p "${PKG_ROOT}/usr/share/kio/servicemenus"
mkdir -p "${PKG_ROOT}/usr/share/konsole"
mkdir -p "${PKG_ROOT}/etc/ananicy.d"
mkdir -p "${PKG_ROOT}/etc/systemd/system/multi-user.target.wants"
mkdir -p "${PKG_ROOT}/usr/share/org.kde.syntax-highlighting/syntax"
mkdir -p "${PKG_ROOT}/usr/share/icons/default"
mkdir -p "${PKG_ROOT}/etc/firefox"
mkdir -p "${PKG_ROOT}/etc/skel/.config/vkBasalt"

cat << 'EOF' > "${PKG_ROOT}/DEBIAN/control"
Package: raytolfas-patch-v26.11.0
Version: 26.11.0-4
Section: misc
Priority: optional
Architecture: amd64
Maintainer: Raytolfas <mixit@raytolfas.com>
Replaces: raytolfas-patch-v26.10.2, raytolfas-patch-v26.10.1, raytolfas-patch-v26.10.0, raytolfas-patch
Breaks: raytolfas-patch-v26.10.2, raytolfas-patch-v26.10.1, raytolfas-patch-v26.10.0, raytolfas-patch
Provides: raytolfas-patch
Recommends: kde-spectacle, vokoscreen-ng, gstreamer1.0-vaapi, mangohud, gamemode, power-profiles-daemon, nano, python3-evdev, libinput-tools, plasma-mobile, vkbasalt, goverlay, zram-tools, btrfs-progs, virtualbox-guest-utils, virtualbox-guest-x11, spice-vdagent
Description: Raytolfas OS D1 v26.11.0 Release & Hotfix Patch
 Redesigned Control Center, Plasma 6 icon & VM Wayland display integration,
 updated RayQuiro .rqb runtime, btrfs-auto-snapshot, and MangoHUD overlay.
EOF

cat << 'EOF' > "${PKG_ROOT}/DEBIAN/postinst"
#!/bin/sh

cat << 'OSREL' > /etc/os-release
NAME="Raytolfas OS"
PRETTY_NAME="Raytolfas OS D1 (v26.11.0)"
ID=raytolfas
ID_LIKE="ubuntu debian"
VERSION="v26.11.0"
VERSION_ID="26.11.0"
VERSION_CODENAME="noble"
HOME_URL="https://os.raytolfas.com"
LOGO=raytolfas-logo
OSREL
cp -f /etc/os-release /usr/lib/os-release 2>/dev/null || true
echo 'Raytolfas OS D1 (v26.11.0) \n \l' > /etc/issue
echo 'Raytolfas OS D1 (v26.11.0)' > /etc/issue.net

mkdir -p /etc/xdg
cat << 'ABOUTDISTRO' > /etc/xdg/kcm-about-distrorc
[General]
LogoPath=/usr/share/pixmaps/raytolfas-logo.png
Website=https://os.raytolfas.com
ABOUTDISTRO

rm -rf /usr/share/raytolfas/welcome \
    /usr/local/bin/raytolfas-welcome \
    /etc/skel/.config/autostart/raytolfas-welcome.desktop \
    /home/*/.config/autostart/raytolfas-welcome.desktop \
    /usr/share/applications/raytolfas-welcome.desktop 2>/dev/null || true

if ! grep -q "MANGOHUD=1" /etc/environment 2>/dev/null; then
    echo "MANGOHUD=1" >> /etc/environment 2>/dev/null || true
fi

cat << 'LOCALE_EOF' > /etc/default/locale
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
LANGUAGE=en_US:en
LOCALE_EOF
cp -f /etc/default/locale /etc/locale.conf 2>/dev/null || true

for u in /etc/skel /home/*; do
    if [ -d "$u/.config" ]; then
        cat << 'LOCALERC' > "$u/.config/plasma-localerc"
[Formats]
LANG=en_US.UTF-8
use24HourClock=true

[Translations]
LANGUAGE=en_US:en
LOCALERC
        if [ "$u" != "/etc/skel" ]; then
            chown $(stat -c '%u:%g' "$u") "$u/.config/plasma-localerc" 2>/dev/null || true
        fi
    fi
done

systemd-hwdb update 2>/dev/null || true
udevadm control --reload-rules 2>/dev/null || true
udevadm trigger 2>/dev/null || true
sysctl --system 2>/dev/null || true

sed -i '/KWIN_DRM_USE_MODIFIERS/d' /etc/environment 2>/dev/null || true
sed -i '/MESA_VK_WSI_PRESENT_MODE/d' /etc/environment 2>/dev/null || true
sed -i '/RADV_PERFTEST/d' /etc/environment 2>/dev/null || true
rm -f /etc/profile.d/kwin-env.sh 2>/dev/null || true

TARGET_VMLINUZ="$(ls -1t /boot/vmlinuz-*cachyos* /boot/vmlinuz-*-generic /boot/vmlinuz-* 2>/dev/null | head -n 1 || true)"
if [ -n "$TARGET_VMLINUZ" ] && [ -f "$TARGET_VMLINUZ" ]; then
    KERNEL_NAME="$(basename "$TARGET_VMLINUZ")"
    VERSION_SUFFIX="${KERNEL_NAME#vmlinuz-}"
    ln -sf "$KERNEL_NAME" /boot/vmlinuz
    ln -sf "boot/$KERNEL_NAME" /vmlinuz 2>/dev/null || true
    if [ -f "/boot/initrd.img-$VERSION_SUFFIX" ]; then
        ln -sf "initrd.img-$VERSION_SUFFIX" /boot/initrd.img
        ln -sf "boot/initrd.img-$VERSION_SUFFIX" /initrd.img 2>/dev/null || true
    fi
fi

kw() {
    if command -v kwriteconfig6 >/dev/null 2>&1; then
        kwriteconfig6 "$@" 2>/dev/null || true
    elif command -v kwriteconfig5 >/dev/null 2>&1; then
        kwriteconfig5 "$@" 2>/dev/null || true
    fi
}

kw --file /etc/xdg/kwinrc --group "Compositing" --key "Backend" "OpenGL"
kw --file /etc/xdg/kwinrc --group "Compositing" --key "GLCore" "true"
kw --file /etc/xdg/kwinrc --group "Compositing" --key "LatencyPolicy" "ExtremelyLow"
kw --file /etc/xdg/kwinrc --group "Compositing" --key "WindowsBlockCompositing" "true"
kw --file /etc/xdg/kwinrc --group "org.kde.kdecoration2" --key "library" "org.kde.kwin.aurorae"
kw --file /etc/xdg/kwinrc --group "org.kde.kdecoration2" --key "theme" "__aurorae__svg__Fluent-round-dark"
kw --file /etc/xdg/kwinrc --group "org.kde.kdecoration2" --key "ButtonsOnRight" "IAX"
kw --file /etc/xdg/kwinrc --group "Wayland" --key "AllowTearing" "true"
kw --file /etc/xdg/kwinrc --group "Plugins" --key "magiclampEnabled" "true"
kw --file /etc/xdg/kwinrc --group "Plugins" --key "scaleEnabled" "true"
kw --file /etc/xdg/kwinrc --group "Plugins" --key "blurEnabled" "true"
kw --file /etc/xdg/kwinrc --group "Plugins" --key "contrastEnabled" "true"
kw --file /etc/xdg/kwinrc --group "Plugins" --key "translucencyEnabled" "true"
kw --file /etc/xdg/kwinrc --group "Effect-blur" --key "BlurStrength" "9"
kw --file /etc/xdg/kwinrc --group "Effect-blur" --key "NoiseStrength" "0"
kw --file /etc/xdg/kwinrc --group "Effect-magiclamp" --key "AnimationDuration" "250"

for u in /etc/skel /home/*; do
    if [ -d "$u/.config" ]; then
        if [ ! -f "$u/.config/kwinrc" ]; then
            cp -f /etc/xdg/kwinrc "$u/.config/kwinrc" 2>/dev/null || true
        else
            kw --file "$u/.config/kwinrc" --group "Compositing" --key "Backend" "OpenGL"
            kw --file "$u/.config/kwinrc" --group "Compositing" --key "GLCore" "true"
            kw --file "$u/.config/kwinrc" --group "Compositing" --key "LatencyPolicy" "ExtremelyLow"
            kw --file "$u/.config/kwinrc" --group "Compositing" --key "WindowsBlockCompositing" "true"
            kw --file "$u/.config/kwinrc" --group "org.kde.kdecoration2" --key "library" "org.kde.kwin.aurorae"
            kw --file "$u/.config/kwinrc" --group "org.kde.kdecoration2" --key "theme" "__aurorae__svg__Fluent-round-dark"
            kw --file "$u/.config/kwinrc" --group "org.kde.kdecoration2" --key "ButtonsOnRight" "IAX"
            kw --file "$u/.config/kwinrc" --group "Wayland" --key "AllowTearing" "true"
            kw --file "$u/.config/kwinrc" --group "Plugins" --key "magiclampEnabled" "true"
            kw --file "$u/.config/kwinrc" --group "Plugins" --key "scaleEnabled" "true"
            kw --file "$u/.config/kwinrc" --group "Plugins" --key "blurEnabled" "true"
            kw --file "$u/.config/kwinrc" --group "Plugins" --key "contrastEnabled" "true"
            kw --file "$u/.config/kwinrc" --group "Plugins" --key "translucencyEnabled" "true"
            kw --file "$u/.config/kwinrc" --group "Effect-blur" --key "BlurStrength" "9"
            kw --file "$u/.config/kwinrc" --group "Effect-blur" --key "NoiseStrength" "0"
            kw --file "$u/.config/kwinrc" --group "Effect-magiclamp" --key "AnimationDuration" "250"
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

if [ -f /etc/xdg/konsolerc ]; then
    for u in /etc/skel /home/*; do
        if [ -d "$u/.config" ]; then
            cp -f /etc/xdg/konsolerc "$u/.config/konsolerc" 2>/dev/null || true
            if [ "$u" != "/etc/skel" ]; then
                chown $(stat -c '%u:%g' "$u") "$u/.config/konsolerc" 2>/dev/null || true
            fi
        fi
    done
fi

if [ -f /etc/xdg/kcminputrc ]; then
    for u in /etc/skel /home/*; do
        if [ -d "$u/.config" ]; then
            cp -f /etc/xdg/kcminputrc "$u/.config/kcminputrc" 2>/dev/null || true
            if [ "$u" != "/etc/skel" ]; then
                chown $(stat -c '%u:%g' "$u") "$u/.config/kcminputrc" 2>/dev/null || true
            fi
        fi
    done
fi

update-alternatives --set x-cursor-theme /usr/share/icons/Bibata-Modern-Classic/cursor.theme 2>/dev/null || true

if [ -f /etc/starship.toml ]; then
    for u in /etc/skel /home/*; do
        if [ -d "$u/.config" ]; then
            cp -f /etc/starship.toml "$u/.config/starship.toml" 2>/dev/null || true
            if [ "$u" != "/etc/skel" ]; then
                chown $(stat -c '%u:%g' "$u") "$u/.config/starship.toml" 2>/dev/null || true
            fi
        fi
    done
fi

if ! grep -q "starship init bash" /etc/bash.bashrc 2>/dev/null; then
    cat << 'STARSHIP_INIT' >> /etc/bash.bashrc
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi
STARSHIP_INIT
fi

if [ -f /etc/vkBasalt.conf ]; then
    for u in /etc/skel /home/*; do
        if [ -d "$u" ]; then
            mkdir -p "$u/.config/vkBasalt" 2>/dev/null || true
            cp -f /etc/vkBasalt.conf "$u/.config/vkBasalt/vkBasalt.conf" 2>/dev/null || true
            if [ "$u" != "/etc/skel" ]; then
                chown -R $(stat -c '%u:%g' "$u") "$u/.config/vkBasalt" 2>/dev/null || true
            fi
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

rm -f /usr/share/plasma/desktoptheme/Fluent-round-dark/icons/start.svgz /usr/share/plasma/desktoptheme/Fluent-round-light/icons/start.svgz 2>/dev/null || true

python3 - << 'PYSCRUB' 2>/dev/null || true
import glob, gzip, re
style_re = re.compile(r'<style\b[^>]*>.*?</style>|<style\b[^>]*/>', re.DOTALL)
for theme in ("Fluent-round-dark", "Fluent-round-light"):
    for path in glob.glob(f"/usr/share/plasma/desktoptheme/{theme}/**/*.svg*", recursive=True):
        is_gz = path.endswith(".svgz")
        data = gzip.open(path, "rt", encoding="utf-8", errors="ignore").read() if is_gz else open(path, "r", encoding="utf-8", errors="ignore").read()
        matches = list(style_re.finditer(data))
        if len(matches) > 1:
            cleaned = data
            for m in reversed(matches[1:]):
                cleaned = cleaned[:m.start()] + cleaned[m.end():]
            if is_gz:
                with gzip.open(path, "wt", encoding="utf-8") as fh:
                    fh.write(cleaned)
            else:
                with open(path, "w", encoding="utf-8") as fh:
                    fh.write(cleaned)
PYSCRUB

TARGET_DARK_ICONS="Papirus-Dark"
TARGET_LIGHT_ICONS="Papirus-Light"

for pdir in /usr/share/icons/Papirus /usr/share/icons/Papirus-Dark /usr/share/icons/Papirus-Light; do
    [ -d "$pdir" ] || continue
    if [ -d "$pdir/48x48/apps" ] && [ -e "$pdir/48x48/apps/plasmadiscover.svg" ]; then
        ln -sf plasmadiscover.svg "$pdir/48x48/apps/org.kde.discover.svg" 2>/dev/null || true
    fi
    if [ -d "$pdir/symbolic/status" ] && [ -e "$pdir/symbolic/status/notification-symbolic.svg" ]; then
        ln -sf notification-symbolic.svg "$pdir/symbolic/status/notification-inactive-symbolic.svg" 2>/dev/null || true
        ln -sf notification-new-symbolic.svg "$pdir/symbolic/status/notification-active-symbolic.svg" 2>/dev/null || true
    fi
done

for lnf_def in /usr/share/plasma/look-and-feel/*/contents/defaults; do
    if [ -f "$lnf_def" ]; then
        sed -i 's/\r$//' "$lnf_def" 2>/dev/null || true
        case "$lnf_def" in
            *light*)
                sed -i "s/cursorTheme=Fluent-dark-cursors/cursorTheme=Bibata-Modern-Classic/g; s/Theme=Papirus-Dark/Theme=${TARGET_LIGHT_ICONS}/g; s/Theme=Fluent-dark/Theme=${TARGET_LIGHT_ICONS}/g; s/widgetStyle=kvantum-dark/widgetStyle=Breeze/g" "$lnf_def" 2>/dev/null || true
                ;;
            *)
                sed -i "s/cursorTheme=Fluent-dark-cursors/cursorTheme=Bibata-Modern-Classic/g; s/Theme=Papirus-Dark/Theme=${TARGET_DARK_ICONS}/g; s/widgetStyle=kvantum-dark/widgetStyle=Breeze/g" "$lnf_def" 2>/dev/null || true
                ;;
        esac
    fi
done

kw --file /etc/xdg/kdeglobals --group "Icons" --key "Theme" "${TARGET_DARK_ICONS}"
kw --file /etc/xdg/kdeglobals --group "General" --key "font" "Noto Sans,11,-1,5,50,0,0,0,0,0"
kw --file /etc/xdg/kdeglobals --group "General" --key "menuFont" "Noto Sans,11,-1,5,50,0,0,0,0,0"
kw --file /etc/xdg/kdeglobals --group "General" --key "smallestReadableFont" "Noto Sans,9,-1,5,50,0,0,0,0,0"
kw --file /etc/xdg/kdeglobals --group "General" --key "toolBarFont" "Noto Sans,11,-1,5,50,0,0,0,0,0"
for u in /etc/skel /home/*; do
    if [ -d "$u/.config" ]; then
        kw --file "$u/.config/kdeglobals" --group "Icons" --key "Theme" "${TARGET_DARK_ICONS}"
        kw --file "$u/.config/kdeglobals" --group "General" --key "font" "Noto Sans,11,-1,5,50,0,0,0,0,0"
        kw --file "$u/.config/kdeglobals" --group "General" --key "menuFont" "Noto Sans,11,-1,5,50,0,0,0,0,0"
        kw --file "$u/.config/kdeglobals" --group "General" --key "smallestReadableFont" "Noto Sans,9,-1,5,50,0,0,0,0,0"
        kw --file "$u/.config/kdeglobals" --group "General" --key "toolBarFont" "Noto Sans,11,-1,5,50,0,0,0,0,0"
        if [ "$u" != "/etc/skel" ] && [ -f "$u/.config/kdeglobals" ]; then
            chown $(stat -c '%u:%g' "$u") "$u/.config/kdeglobals" 2>/dev/null || true
        fi
    fi
done

if [ -f /usr/share/applications/raytolfas-android.desktop ]; then
    sed -i 's/^Icon=.*/Icon=waydroid/' /usr/share/applications/raytolfas-android.desktop 2>/dev/null || true
fi

if [ -f /usr/share/pixmaps/start-here-raytolfas.svg ]; then
    find /usr/share/icons -maxdepth 5 -name 'start-here*.svg' 2>/dev/null | while IFS= read -r st_svg; do
        [ -n "$st_svg" ] || continue
        rm -f "$st_svg"
        cp -f /usr/share/pixmaps/start-here-raytolfas.svg "$st_svg"
    done
fi
rm -f /usr/share/icons/*/icon-theme.cache /usr/share/icons/.*/icon-theme.cache 2>/dev/null || true

if [ -f /usr/share/applications/systemsettings.desktop ] && [ ! -e /usr/share/applications/org.kde.systemsettings.desktop ]; then
    ln -sf systemsettings.desktop /usr/share/applications/org.kde.systemsettings.desktop 2>/dev/null || true
fi
if [ -f /usr/share/applications/org.kde.systemsettings.desktop ] && [ ! -e /usr/share/applications/systemsettings.desktop ]; then
    ln -sf org.kde.systemsettings.desktop /usr/share/applications/systemsettings.desktop 2>/dev/null || true
fi

mkdir -p /etc/systemd/system/virtualbox-guest-utils.service.d /etc/xdg/autostart
cat << 'VBOX_DROPIN' > /etc/systemd/system/virtualbox-guest-utils.service.d/override.conf
[Unit]
After=systemd-udevd.service
Before=display-manager.service sddm.service

[Service]
Environment=HOME=/root
ExecStartPre=-/sbin/modprobe vboxguest
ExecStartPre=-/sbin/modprobe vboxsf
ExecStartPre=-/sbin/modprobe vmwgfx
ExecStartPre=-/sbin/modprobe vboxvideo
ExecStartPost=-/bin/sh -c 'pgrep -f "VBoxClient.*--vmsvga" >/dev/null 2>&1 || HOME=/root /usr/bin/VBoxClient --vmsvga'
VBOX_DROPIN
chmod 0644 /etc/systemd/system/virtualbox-guest-utils.service.d/override.conf 2>/dev/null || true

cat << 'VMSESS' > /usr/local/bin/raytolfas-vm-session
#!/usr/bin/env bash
if [ -c /dev/vboxguest ] || [ -c /dev/vboxuser ]; then
    for pidf in "$HOME"/.vboxclient-*.pid; do
        [ -e "$pidf" ] && [ ! -w "$pidf" ] && rm -f "$pidf"
    done
    if [ -x /usr/bin/VBoxClient ]; then
        /usr/bin/VBoxClient --clipboard 2>/dev/null || true
        /usr/bin/VBoxClient --draganddrop 2>/dev/null || true
        /usr/bin/VBoxClient --vmsvga-session 2>/dev/null || true
        /usr/bin/VBoxClient --display 2>/dev/null || true
    fi
fi
if [ -c /dev/virtio-ports/com.redhat.spice.0 ] && command -v spice-vdagent >/dev/null 2>&1; then
    pgrep -u "$UID" -x spice-vdagent >/dev/null 2>&1 || spice-vdagent 2>/dev/null || true
fi
VMSESS
chmod 0755 /usr/local/bin/raytolfas-vm-session 2>/dev/null || true

cat << 'VMAUTO' > /etc/xdg/autostart/raytolfas-vm-session.desktop
[Desktop Entry]
Type=Application
Name=VM Guest Session Helper
Exec=/usr/local/bin/raytolfas-vm-session
Terminal=false
NoDisplay=true
X-KDE-autostart-phase=1
VMAUTO
chmod 0644 /etc/xdg/autostart/raytolfas-vm-session.desktop 2>/dev/null || true

/usr/local/bin/raytolfas-waydroid-net-fix 2>/dev/null || true

systemctl enable --now power-profiles-daemon 2>/dev/null || true
powerprofilesctl set balanced 2>/dev/null || true

timedatectl set-local-rtc 1 --adjust-system-clock 2>/dev/null || true
systemctl restart udisks2 2>/dev/null || true

systemctl disable --now raytolfas-zram.service 2>/dev/null || true
rm -f /etc/systemd/system/raytolfas-zram.service /etc/systemd/system/basic.target.wants/raytolfas-zram.service 2>/dev/null || true

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
chmod 0755 /usr/local/bin/btrfs-auto-snapshot /usr/bin/btrfs-auto-snapshot 2>/dev/null || true
chmod 0755 /usr/local/bin/limine-snapper-ext /usr/bin/limine-snapper-ext 2>/dev/null || true
chmod 0755 /usr/local/bin/raytolfas-proton-update /usr/bin/raytolfas-proton-update 2>/dev/null || true
chmod 0755 /usr/local/bin/ananicy-cpp /usr/bin/ananicy-cpp 2>/dev/null || true
chmod 0755 /usr/local/bin/raytolfas-turbo /usr/bin/raytolfas-turbo 2>/dev/null || true
chmod 0755 /usr/local/bin/raytolfas-dev /usr/bin/raytolfas-dev 2>/dev/null || true
chmod 0755 /usr/local/bin/raytolfas-bench /usr/bin/raytolfas-bench 2>/dev/null || true
chmod 0755 /usr/local/bin/raytolfas-appimage /usr/bin/raytolfas-appimage 2>/dev/null || true
chmod 0755 /usr/local/bin/starship /usr/bin/starship 2>/dev/null || true
rm -f /usr/local/bin/raytolfas-nvidia-setup /usr/bin/raytolfas-nvidia-setup 2>/dev/null || true
cat << 'BALOO_EOF' > /etc/xdg/baloofilerc
[Basic Settings]
Indexing-Enabled=false
BALOO_EOF
for u in /etc/skel /home/*; do
    if [ -d "$u/.config" ]; then
        cp -f /etc/xdg/baloofilerc "$u/.config/baloofilerc"
        if [ "$u" != "/etc/skel" ]; then
            chown $(stat -c '%u:%g' "$u") "$u/.config/baloofilerc" 2>/dev/null || true
        fi
    fi
done
rm -f /etc/xdg/autostart/baloo_file.desktop

python3 - << 'PYICONS'
import gzip, os, re, shutil, subprocess

rootfs = ""
fluent_base = f"{rootfs}/usr/share/icons/.Fluent-base"
fluent_dark = f"{rootfs}/usr/share/icons/.Fluent-dark-base"
src_icons = "/var/lib/raytolfas/src-themes/fluent-kde/plasma/desktoptheme/Fluent-round/icons"
cache_dir = f"{rootfs}/var/cache/raytolfas-tray-icons" if rootfs else "/var/cache/raytolfas-tray-icons"
os.makedirs(cache_dir, exist_ok=True)

cat_map = {
    "applications-development": f"{fluent_base}/32/categories/applications-development.svg",
    "applications-games": f"{fluent_base}/32/categories/applications-games.svg",
    "applications-internet": f"{fluent_base}/32/categories/applications-internet.svg",
    "applications-multimedia": f"{fluent_base}/32/categories/applications-multimedia.svg",
    "applications-system": f"{fluent_base}/32/categories/preferences-system.svg",
    "applications-utilities": f"{fluent_base}/32/categories/applications-utilities.svg",
    "applications-education": f"{fluent_base}/32/categories/applications-education.svg",
    "applications-graphics": f"{fluent_base}/32/categories/applications-graphics.svg",
    "applications-office": f"{fluent_base}/32/categories/applications-office.svg",
    "applications-science": f"{fluent_base}/32/categories/applications-science.svg",
    "applications-accessories": f"{fluent_base}/32/categories/applications-utilities.svg",
    "preferences-system": f"{fluent_base}/32/categories/preferences-system.svg",
    "system-help": f"{fluent_base}/scalable/apps/system-help.svg",
}

for name, src in cat_map.items():
    if not os.path.exists(src):
        continue
    for bsz in ("22", "24", "32"):
        bdest = f"{rootfs}/usr/share/icons/breeze-dark/categories/{bsz}/{name}.svg"
        bsym = f"{rootfs}/usr/share/icons/breeze-dark/categories/{bsz}/{name}-symbolic.svg"
        if os.path.exists(os.path.dirname(bdest)):
            shutil.copy2(src, bdest)
            shutil.copy2(src, bsym)
    for psz in ("16x16", "22x22", "24x24", "32x32", "48x48"):
        pdest = f"{rootfs}/usr/share/icons/Papirus-Dark/{psz}/categories/{name}.svg"
        if os.path.exists(os.path.dirname(pdest)):
            shutil.copy2(src, pdest)
    psym = f"{rootfs}/usr/share/icons/Papirus-Dark/symbolic/categories/{name}-symbolic.svg"
    if os.path.exists(os.path.dirname(psym)):
        shutil.copy2(src, psym)

def export_svg(svgz_file, eid, out_name, sz=22):
    sp = os.path.join(src_icons, svgz_file)
    if not os.path.exists(sp):
        return
    tmp_svg = f"/tmp/u_{svgz_file}.svg"
    try:
        with gzip.open(sp, "rt", encoding="utf-8", errors="ignore") as f:
            content = f.read()
        with open(tmp_svg, "w", encoding="utf-8") as f:
            f.write(content)
        out_svg = os.path.join(cache_dir, out_name)
        cmd = ["rsvg-convert", "-i", eid, "-f", "svg", "-w", str(sz), "-h", str(sz), "-o", out_svg, tmp_svg]
        if subprocess.run(cmd, capture_output=True).returncode == 0:
            with open(out_svg, "r", encoding="utf-8") as f:
                txt = f.read()
            txt = re.sub(r'<rect\b[^>]*\bfill="none"[^>]*/>', '', txt)
            txt = re.sub(r'<rect\b[^>]*\bfill:none[^>]*/>', '', txt)
            txt = re.sub(r'<rect\b[^>]*\bfill="none"[^>]*>.*?</rect>', '', txt, flags=re.DOTALL)
            txt = re.sub(r'<rect\b[^>]*\bfill:none[^>]*>.*?</rect>', '', txt, flags=re.DOTALL)
            txt = re.sub(r'fill="(?!none)[^"]+"', 'fill="currentColor" class="ColorScheme-Text"', txt)
            txt = re.sub(r'fill-rule="[^"]+"', '', txt)
            txt = re.sub(r'fill-opacity="[^"]+"', '', txt)
            st = '<defs><style id="current-color-scheme" type="text/css">.ColorScheme-Text { color:#dfdfdf; }</style></defs>'
            txt = re.sub(r'(<svg\b[^>]*>)', r'\1\n' + st, txt, count=1)
            with open(out_svg, "w", encoding="utf-8") as f:
                f.write(txt)
    except Exception:
        pass

extractions = [
    ("audio.svgz", "22-22-audio-volume-high", "audio-volume-high.svg", 22),
    ("audio.svgz", "22-22-audio-volume-medium", "audio-volume-medium.svg", 22),
    ("audio.svgz", "22-22-audio-volume-low", "audio-volume-low.svg", 22),
    ("audio.svgz", "22-22-audio-volume-muted", "audio-volume-muted.svg", 22),
    ("network.svgz", "22-22-network-wired-activated", "network-wired.svg", 22),
    ("network.svgz", "22-22-network-wired-activated", "network-wired-activated.svg", 22),
    ("network.svgz", "network-wireless-connected-100", "network-wireless-connected-100.svg", 22),
    ("network.svgz", "network-wireless-connected-80", "network-wireless-connected-80.svg", 22),
    ("network.svgz", "network-wireless-connected-60", "network-wireless-connected-60.svg", 22),
    ("network.svgz", "network-wireless-connected-40", "network-wireless-connected-40.svg", 22),
    ("network.svgz", "network-wireless-connected-20", "network-wireless-connected-20.svg", 22),
    ("network.svgz", "network-wireless-disconnected", "network-wireless-disconnected.svg", 22),
    ("network.svgz", "network-wireless-off", "network-wireless-off.svg", 22),
    ("network.svgz", "22-22-network-vpn", "network-vpn.svg", 22),
    ("device.svgz", "22-22-device-notifier", "device-notifier.svg", 22),
    ("notification.svgz", "22-22-notification-inactive", "notification.svg", 22),
    ("notification.svgz", "22-22-notification-inactive", "notification-inactive.svg", 22),
    ("notification.svgz", "22-22-notification-active", "notification-active.svg", 22),
    ("notification.svgz", "22-22-notification-disabled", "notification-disabled.svg", 22),
    ("video.svgz", "22-22-video-display-brightness", "brightness-high.svg", 22),
    ("user.svgz", "22-22-user-desktop", "user-desktop.svg", 22),
    ("go.svgz", "go-up", "arrow-up.svg", 22),
    ("go.svgz", "go-down", "arrow-down.svg", 22),
    ("battery.svgz", "22-22-Battery", "battery.svg", 22),
    ("battery.svgz", "22-22-Fill100", "battery-100.svg", 22),
    ("battery.svgz", "22-22-Fill80", "battery-080.svg", 22),
    ("battery.svgz", "22-22-Fill60", "battery-060.svg", 22),
    ("battery.svgz", "22-22-Fill40", "battery-040.svg", 22),
    ("battery.svgz", "22-22-Fill20", "battery-020.svg", 22),
    ("battery.svgz", "22-22-Fill0", "battery-000.svg", 22),
    ("battery.svgz", "22-22-AcAdapter", "battery-charging.svg", 22),
]

for item in extractions:
    export_svg(item[0], item[1], item[2], item[3])

bright_src = "/var/lib/raytolfas/src-themes/fluent-icons/src/24/panel/brightness-high.svg"
if os.path.exists(bright_src):
    shutil.copy2(bright_src, os.path.join(cache_dir, "brightness-high.svg"))

tray_icons_list = [
    "audio-volume-high", "audio-volume-medium", "audio-volume-low", "audio-volume-muted",
    "network-wired", "network-wired-activated", "network-vpn",
    "network-wireless-connected-100", "network-wireless-connected-80", "network-wireless-connected-60",
    "network-wireless-connected-40", "network-wireless-connected-20", "network-wireless-disconnected", "network-wireless-off",
    "device-notifier", "notification", "notification-inactive", "notification-active", "notification-disabled",
    "brightness-high", "user-desktop", "arrow-up", "arrow-down",
    "battery", "battery-100", "battery-080", "battery-060", "battery-040", "battery-020", "battery-000", "battery-charging"
]

target_dirs = [
    f"{rootfs}/usr/share/icons/breeze-dark/status/24",
    f"{rootfs}/usr/share/icons/breeze-dark/status/22",
    f"{rootfs}/usr/share/icons/breeze-dark/preferences/24",
    f"{rootfs}/usr/share/icons/breeze-dark/preferences/22",
    f"{rootfs}/usr/share/icons/breeze-dark/actions/24",
    f"{rootfs}/usr/share/icons/breeze-dark/actions/22",
    f"{rootfs}/usr/share/icons/breeze-dark/actions/16",
    f"{rootfs}/usr/share/icons/breeze-dark/devices/24",
    f"{rootfs}/usr/share/icons/breeze-dark/devices/22",
    f"{rootfs}/usr/share/icons/breeze-dark/devices/16",
    f"{rootfs}/usr/share/icons/Papirus-Dark/symbolic/status",
    f"{rootfs}/usr/share/icons/Papirus-Dark/symbolic/devices",
    f"{rootfs}/usr/share/icons/Papirus-Dark/symbolic/actions",
    f"{rootfs}/usr/share/icons/Papirus-Dark/24x24/panel",
    f"{rootfs}/usr/share/icons/Papirus-Dark/22x22/panel",
    f"{rootfs}/usr/share/icons/Papirus-Dark/24x24/status",
    f"{rootfs}/usr/share/icons/Papirus-Dark/22x22/status",
    f"{rootfs}/usr/share/icons/Papirus-Dark/24x24/devices",
    f"{rootfs}/usr/share/icons/Papirus-Dark/22x22/devices",
]

for tdir in target_dirs:
    if not os.path.exists(tdir):
        continue
    for ic in tray_icons_list:
        src_svg = os.path.join(cache_dir, f"{ic}.svg")
        if not os.path.exists(src_svg):
            continue
        dest = os.path.join(tdir, f"{ic}.svg")
        sym_dest = os.path.join(tdir, f"{ic}-symbolic.svg")
        try:
            if os.path.islink(dest) or os.path.exists(dest):
                os.remove(dest)
            shutil.copy2(src_svg, dest)
            if os.path.islink(sym_dest) or os.path.exists(sym_dest):
                os.remove(sym_dest)
            shutil.copy2(src_svg, sym_dest)
        except Exception:
            pass
    for link_name, target_name in [
        ("arrow-up-tiny-symbolic", "arrow-up"),
        ("arrow-down-tiny-symbolic", "arrow-down"),
        ("network-wireless-symbolic", "network-wireless-connected-100"),
        ("video-display-brightness", "brightness-high"),
    ]:
        src_svg = os.path.join(cache_dir, f"{target_name}.svg")
        if os.path.exists(src_svg):
            dest = os.path.join(tdir, f"{link_name}.svg")
            try:
                if os.path.islink(dest) or os.path.exists(dest):
                    os.remove(dest)
                shutil.copy2(src_svg, dest)
            except Exception:
                pass
PYICONS

systemctl daemon-reload 2>/dev/null || true
systemctl enable --now ananicy-cpp.service 2>/dev/null || true
systemctl mask whoopsie.service apport.service kerneloops.service systemd-pstore.service apt-daily.service apt-daily.timer apt-daily-upgrade.service apt-daily-upgrade.timer kde-baloo.service 2>/dev/null || true
ldconfig 2>/dev/null || true

exit 0
EOF
chmod 0755 "${PKG_ROOT}/DEBIAN/postinst"
chmod 0755 "${PKG_ROOT}/DEBIAN"

if [ -f "${REPO_ROOT}/assets/logo.svg" ]; then
    cp -f "${REPO_ROOT}/assets/logo.svg" "${PKG_ROOT}/usr/share/pixmaps/raytolfas-logo.svg"
    cp -f "${REPO_ROOT}/assets/logo.svg" "${PKG_ROOT}/usr/share/pixmaps/start-here-raytolfas.svg"
    cp -f "${REPO_ROOT}/assets/logo.svg" "${PKG_ROOT}/usr/share/icons/hicolor/scalable/apps/raytolfas-logo.svg"
    cp -f "${REPO_ROOT}/assets/logo.svg" "${PKG_ROOT}/usr/share/icons/hicolor/scalable/apps/start-here-raytolfas.svg"
fi
if [ -f "${REPO_ROOT}/assets/logo.png" ]; then
    cp -f "${REPO_ROOT}/assets/logo.png" "${PKG_ROOT}/usr/share/pixmaps/raytolfas-logo.png"
    cp -f "${REPO_ROOT}/assets/logo.png" "${PKG_ROOT}/usr/share/icons/hicolor/512x512/apps/raytolfas-logo.png"
    cp -f "${REPO_ROOT}/assets/logo.png" "${PKG_ROOT}/usr/share/icons/hicolor/512x512/apps/start-here-raytolfas.png"
fi
if [ -f "${REPO_ROOT}/assets/logo.txt" ]; then
    cp -f "${REPO_ROOT}/assets/logo.txt" "${PKG_ROOT}/usr/share/fastfetch/raytolfas-logo.txt"
fi

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
if [ -f "${REPO_ROOT}/config/apt/80-btrfs-auto-snapshot" ]; then
    cp -f "${REPO_ROOT}/config/apt/80-btrfs-auto-snapshot" "${PKG_ROOT}/etc/apt/apt.conf.d/80-btrfs-auto-snapshot"
    chmod 0644 "${PKG_ROOT}/etc/apt/apt.conf.d/80-btrfs-auto-snapshot"
fi

cat << 'WINEDESK' > "${PKG_ROOT}/usr/share/applications/raytolfas-wine.desktop"
[Desktop Entry]
Type=Application
Name=Run Windows Program (Proton-GE)
Comment=Run Windows .exe applications with Proton-GE compatibility layer
Exec=raytolfas-proton %f
Icon=wine
NoDisplay=true
MimeType=application/x-ms-dos-executable;application/x-msdownload;application/x-dosexec;application/vnd.microsoft.portable-executable;
Categories=System;Emulator;
WINEDESK
chmod 0644 "${PKG_ROOT}/usr/share/applications/raytolfas-wine.desktop"

for tool in raytolfas-control-center raytolfas-proton raytolfas-proton-update raytolfas-android raytolfas-apk-install raytolfas-waydroid-setup raytolfas-waydroid-net-fix raytolfas-mobile-test prime-run raytolfas-rqb-runner raytolfas-upgrade-iso btrfs-auto-snapshot limine-snapper-ext ananicy-cpp raytolfas-turbo raytolfas-dev raytolfas-bench raytolfas-appimage raytolfas-desktop-mode raytolfas-console-mode raytolfas-spotlight raytolfas-clean raytolfas-ri-growpart starship; do
    if [ -f "${REPO_ROOT}/scripts/tools/${tool}" ]; then
        cp -f "${REPO_ROOT}/scripts/tools/${tool}" "${PKG_ROOT}/usr/local/bin/${tool}"
        cp -f "${REPO_ROOT}/scripts/tools/${tool}" "${PKG_ROOT}/usr/bin/${tool}"
        chmod 0755 "${PKG_ROOT}/usr/local/bin/${tool}" "${PKG_ROOT}/usr/bin/${tool}"
    fi
done

cp -f "${REPO_ROOT}/apps/control-center/main.py" "${PKG_ROOT}/usr/share/raytolfas/control-center/main.py"
cp -f "${REPO_ROOT}/apps/control-center/ControlCenter.qml" "${PKG_ROOT}/usr/share/raytolfas/control-center/ControlCenter.qml"
chmod 0755 "${PKG_ROOT}/usr/share/raytolfas/control-center/main.py"
chmod 0644 "${PKG_ROOT}/usr/share/raytolfas/control-center/ControlCenter.qml"

for app_dir in m1-shell desktop-mode console-mode spotlight; do
    if [ -d "${REPO_ROOT}/apps/${app_dir}" ]; then
        mkdir -p "${PKG_ROOT}/usr/share/raytolfas/${app_dir}"
        cp -rf "${REPO_ROOT}/apps/${app_dir}/"* "${PKG_ROOT}/usr/share/raytolfas/${app_dir}/"
        rm -rf "${PKG_ROOT}/usr/share/raytolfas/${app_dir}/__pycache__"
        chmod 0755 "${PKG_ROOT}/usr/share/raytolfas/${app_dir}/main.py"
    fi
done

if [ -f "${REPO_ROOT}/config/mobile/plasmamobilerc" ]; then
    cp -f "${REPO_ROOT}/config/mobile/plasmamobilerc" "${PKG_ROOT}/etc/xdg/plasmamobilerc"
    chmod 0644 "${PKG_ROOT}/etc/xdg/plasmamobilerc"
fi

if [ -f "${REPO_ROOT}/config/sessions/raytolfas-console.desktop" ]; then
    mkdir -p "${PKG_ROOT}/usr/share/wayland-sessions"
    cp -f "${REPO_ROOT}/config/sessions/raytolfas-console.desktop" "${PKG_ROOT}/usr/share/wayland-sessions/raytolfas-console.desktop"
    chmod 0644 "${PKG_ROOT}/usr/share/wayland-sessions/raytolfas-console.desktop"
fi

for desk_entry in raytolfas-control-center.desktop raytolfas-console-mode.desktop raytolfas-desktop-mode.desktop raytolfas-spotlight.desktop; do
    if [ -f "${REPO_ROOT}/config/applications/${desk_entry}" ]; then
        cp -f "${REPO_ROOT}/config/applications/${desk_entry}" "${PKG_ROOT}/usr/share/applications/${desk_entry}"
        chmod 0644 "${PKG_ROOT}/usr/share/applications/${desk_entry}"
    fi
done

cp -f "${REPO_ROOT}/config/gaming/gamemode.ini" "${PKG_ROOT}/etc/gamemode.ini"
cp -f "${REPO_ROOT}/config/sysctl/99-raytolfas-performance.conf" "${PKG_ROOT}/etc/sysctl.d/99-raytolfas-performance.conf"
cp -f "${REPO_ROOT}/config/limits/99-raytolfas-gaming.conf" "${PKG_ROOT}/etc/security/limits.d/99-raytolfas-gaming.conf"
cp -f "${REPO_ROOT}/config/pipewire/10-lowlatency.conf" "${PKG_ROOT}/etc/pipewire/pipewire.conf.d/10-lowlatency.conf"
cp -f "${REPO_ROOT}/config/udev/70-mouse-keys.hwdb" "${PKG_ROOT}/etc/udev/hwdb.d/70-mouse-keys.hwdb"
cp -f "${REPO_ROOT}/config/udev/60-ioschedulers.rules" "${PKG_ROOT}/etc/udev/rules.d/60-ioschedulers.rules"
cp -f "${REPO_ROOT}/config/kde/kglobalshortcutsrc" "${PKG_ROOT}/etc/xdg/kglobalshortcutsrc"
cp -f "${REPO_ROOT}/config/udisks2/mount_options.conf" "${PKG_ROOT}/etc/udisks2/mount_options.conf"
cp -f "${REPO_ROOT}/config/mangohud/MangoHud.conf" "${PKG_ROOT}/etc/MangoHud.conf"
cp -f "${REPO_ROOT}/config/mangohud/MangoHud.conf" "${PKG_ROOT}/etc/skel/.config/MangoHud/MangoHud.conf"
cp -f "${REPO_ROOT}/config/calamares/bootloader.conf" "${PKG_ROOT}/etc/calamares/modules/bootloader.conf"
cp -f "${REPO_ROOT}/config/calamares/partition.conf" "${PKG_ROOT}/etc/calamares/modules/partition.conf"
cp -f "${REPO_ROOT}/config/calamares/displaymanager.conf" "${PKG_ROOT}/etc/calamares/modules/displaymanager.conf"

chmod 0644 "${PKG_ROOT}/etc/gamemode.ini"
chmod 0644 "${PKG_ROOT}/etc/sysctl.d/99-raytolfas-performance.conf"
chmod 0644 "${PKG_ROOT}/etc/security/limits.d/99-raytolfas-gaming.conf"
chmod 0644 "${PKG_ROOT}/etc/pipewire/pipewire.conf.d/10-lowlatency.conf"
chmod 0644 "${PKG_ROOT}/etc/udev/hwdb.d/70-mouse-keys.hwdb"
chmod 0644 "${PKG_ROOT}/etc/udev/rules.d/60-ioschedulers.rules"
chmod 0644 "${PKG_ROOT}/etc/xdg/kglobalshortcutsrc"
chmod 0644 "${PKG_ROOT}/etc/udisks2/mount_options.conf"
chmod 0644 "${PKG_ROOT}/etc/MangoHud.conf"
chmod 0644 "${PKG_ROOT}/etc/skel/.config/MangoHud/MangoHud.conf"
chmod 0644 "${PKG_ROOT}/etc/calamares/modules/bootloader.conf"
chmod 0644 "${PKG_ROOT}/etc/calamares/modules/partition.conf"

if [ -f "${REPO_ROOT}/config/kde/kcminputrc" ]; then
    cp -f "${REPO_ROOT}/config/kde/kcminputrc" "${PKG_ROOT}/etc/xdg/kcminputrc"
    chmod 0644 "${PKG_ROOT}/etc/xdg/kcminputrc"
fi
if [ -f "${REPO_ROOT}/config/icons/default-index.theme" ]; then
    cp -f "${REPO_ROOT}/config/icons/default-index.theme" "${PKG_ROOT}/usr/share/icons/default/index.theme"
    chmod 0644 "${PKG_ROOT}/usr/share/icons/default/index.theme"
fi
if [ -f "${REPO_ROOT}/config/starship/starship.toml" ]; then
    cp -f "${REPO_ROOT}/config/starship/starship.toml" "${PKG_ROOT}/etc/starship.toml"
    chmod 0644 "${PKG_ROOT}/etc/starship.toml"
fi
if [ -f "${REPO_ROOT}/config/udev/70-game-controllers.rules" ]; then
    cp -f "${REPO_ROOT}/config/udev/70-game-controllers.rules" "${PKG_ROOT}/etc/udev/rules.d/70-game-controllers.rules"
    chmod 0644 "${PKG_ROOT}/etc/udev/rules.d/70-game-controllers.rules"
fi
if [ -f "${REPO_ROOT}/config/vkbasalt/vkBasalt.conf" ]; then
    cp -f "${REPO_ROOT}/config/vkbasalt/vkBasalt.conf" "${PKG_ROOT}/etc/vkBasalt.conf"
    cp -f "${REPO_ROOT}/config/vkbasalt/vkBasalt.conf" "${PKG_ROOT}/etc/skel/.config/vkBasalt/vkBasalt.conf"
    chmod 0644 "${PKG_ROOT}/etc/vkBasalt.conf" "${PKG_ROOT}/etc/skel/.config/vkBasalt/vkBasalt.conf"
fi
if [ -f "${REPO_ROOT}/config/syntax/rayquiro.xml" ]; then
    cp -f "${REPO_ROOT}/config/syntax/rayquiro.xml" "${PKG_ROOT}/usr/share/org.kde.syntax-highlighting/syntax/rayquiro.xml"
    chmod 0644 "${PKG_ROOT}/usr/share/org.kde.syntax-highlighting/syntax/rayquiro.xml"
fi
if [ -f "${REPO_ROOT}/config/firefox/syspref.js" ]; then
    cp -f "${REPO_ROOT}/config/firefox/syspref.js" "${PKG_ROOT}/etc/firefox/syspref.js"
    chmod 0644 "${PKG_ROOT}/etc/firefox/syspref.js"
fi
if [ -f "${REPO_ROOT}/config/applications/raytolfas-turbo.desktop" ]; then
    cp -f "${REPO_ROOT}/config/applications/raytolfas-turbo.desktop" "${PKG_ROOT}/usr/share/applications/raytolfas-turbo.desktop"
    chmod 0644 "${PKG_ROOT}/usr/share/applications/raytolfas-turbo.desktop"
fi

if [ -d "${REPO_ROOT}/config/servicemenus" ]; then
    cp -f "${REPO_ROOT}/config/servicemenus/"*.desktop "${PKG_ROOT}/usr/share/kio/servicemenus/"
    chmod 0755 "${PKG_ROOT}/usr/share/kio/servicemenus/"*.desktop
fi

if [ -d "${REPO_ROOT}/config/konsole" ]; then
    cp -f "${REPO_ROOT}/config/konsole/Raytolfas.profile" "${PKG_ROOT}/usr/share/konsole/Raytolfas.profile"
    cp -f "${REPO_ROOT}/config/konsole/RaytolfasDark.colorscheme" "${PKG_ROOT}/usr/share/konsole/RaytolfasDark.colorscheme"
    cp -f "${REPO_ROOT}/config/konsole/konsolerc" "${PKG_ROOT}/etc/xdg/konsolerc"
    chmod 0644 "${PKG_ROOT}/usr/share/konsole/Raytolfas.profile" "${PKG_ROOT}/usr/share/konsole/RaytolfasDark.colorscheme" "${PKG_ROOT}/etc/xdg/konsolerc"
fi

if [ -d "${REPO_ROOT}/config/ananicy.d" ]; then
    cp -rf "${REPO_ROOT}/config/ananicy.d/"* "${PKG_ROOT}/etc/ananicy.d/"
fi

if [ -f "${REPO_ROOT}/config/systemd/ananicy-cpp.service" ]; then
    cp -f "${REPO_ROOT}/config/systemd/ananicy-cpp.service" "${PKG_ROOT}/etc/systemd/system/ananicy-cpp.service"
    chmod 0644 "${PKG_ROOT}/etc/systemd/system/ananicy-cpp.service"
    ln -sf "/etc/systemd/system/ananicy-cpp.service" "${PKG_ROOT}/etc/systemd/system/multi-user.target.wants/ananicy-cpp.service"
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

dpkg-deb --build --root-owner-group "${PKG_ROOT}" "${OUTPUT_DIR}/raytolfas-patch-v26.11.0_amd64.deb"

echo "[patch] Built successfully: ${OUTPUT_DIR}/raytolfas-patch-v26.11.0_amd64.deb"
