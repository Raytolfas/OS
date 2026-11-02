#!/usr/bin/env bash
set -euo pipefail

ROOTFS="/var/lib/raytolfas/plasma-rootfs"

echo "[sync] Updating os-release and KDE Info Center branding..."
cat << 'EOF' > "${ROOTFS}/etc/os-release"
NAME="Raytolfas OS"
PRETTY_NAME="Raytolfas OS D1 (v26.11.0)"
ID=raytolfas
ID_LIKE="ubuntu debian"
VERSION="v26.11.0"
VERSION_ID="26.11.0"
VERSION_CODENAME="noble"
HOME_URL="https://os.raytolfas.com"
LOGO=raytolfas-logo
EOF
cp -f "${ROOTFS}/etc/os-release" "${ROOTFS}/usr/lib/os-release" 2>/dev/null || true

echo 'Raytolfas OS D1 (v26.11.0) \n \l' > "${ROOTFS}/etc/issue"
echo 'Raytolfas OS D1 (v26.11.0)' > "${ROOTFS}/etc/issue.net"

mkdir -p "${ROOTFS}/etc/xdg"
cat << 'EOF' > "${ROOTFS}/etc/xdg/kcm-about-distrorc"
[General]
LogoPath=/usr/share/pixmaps/raytolfas-logo.png
Website=https://os.raytolfas.com
EOF

echo "[sync] Setting hostname to d1-pc..."
echo "d1-pc" > "${ROOTFS}/etc/hostname"
sed -i "s/raytolfas-pc/d1-pc/g" "${ROOTFS}/etc/hosts" 2>/dev/null || true

echo "[sync] Updating Calamares branding..."
if [ -f "${ROOTFS}/etc/calamares/branding/raytolfas/branding.desc" ]; then
    sed -i "s/v26.09.0/v26.11.0/g; s/v26.10.0/v26.11.0/g; s/v26.10.1/v26.11.0/g; s/v26.10.2/v26.11.0/g" "${ROOTFS}/etc/calamares/branding/raytolfas/branding.desc"
    sed -i "s/D1 Alpha/v26.11.0/g" "${ROOTFS}/etc/calamares/branding/raytolfas/branding.desc"
    sed -i "s/Raytolfas OS D1 Alpha/Raytolfas OS D1/g" "${ROOTFS}/etc/calamares/branding/raytolfas/branding.desc"
    sed -i "s|https://raytolfas.com|https://os.raytolfas.com|g; s|https://raytolfas.org|https://os.raytolfas.com|g; s|https://os.raytolfas.cc|https://os.raytolfas.com|g" "${ROOTFS}/etc/calamares/branding/raytolfas/branding.desc"
    cat << 'SHOWQML' > "${ROOTFS}/etc/calamares/branding/raytolfas/show.qml"
import QtQuick

Rectangle {
    color: "#090b10"
    Text {
        anchors.centerIn: parent
        text: "Installing Raytolfas OS..."
        color: "#f1f5f9"
        font.pixelSize: 16
        font.family: "Noto Sans"
    }
}
SHOWQML
fi

cat << 'CALWRAP' > "${ROOTFS}/usr/local/bin/raytolfas-install"
#!/usr/bin/env bash
xhost +si:localuser:root 2>/dev/null || xhost + 2>/dev/null || true
export DISPLAY="${DISPLAY:-:0}"
export QT_QPA_PLATFORM="xcb"
export QT_AUTO_SCREEN_SCALE_FACTOR=1
exec sudo -E /usr/bin/calamares -d "$@"
CALWRAP
chmod 0755 "${ROOTFS}/usr/local/bin/raytolfas-install"

if [ -f "${ROOTFS}/usr/local/bin/raytolfas-login-sound" ]; then
    cat << 'SNDSCRIPT' > "${ROOTFS}/usr/local/bin/raytolfas-login-sound"
#!/usr/bin/env bash
sleep 1.5
amixer set Master unmute 50% 2>/dev/null || true
amixer set Speaker unmute 50% 2>/dev/null || true
amixer set Headphone unmute 50% 2>/dev/null || true
wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 2>/dev/null || true
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.50 2>/dev/null || true

if [ -f /usr/share/sounds/raytolfas/login.ogg ]; then
    pw-play /usr/share/sounds/raytolfas/login.ogg 2>/dev/null || \
    paplay /usr/share/sounds/raytolfas/login.ogg 2>/dev/null || \
    mpv --no-video --volume=50 /usr/share/sounds/raytolfas/login.ogg 2>/dev/null || true
fi
SNDSCRIPT
    chmod 0755 "${ROOTFS}/usr/local/bin/raytolfas-login-sound"
fi

if [ -d "${ROOTFS}/usr/share/wallpapers/Raytolfas" ]; then
    cat << 'WPMETA' > "${ROOTFS}/usr/share/wallpapers/Raytolfas/metadata.json"
{
    "KPlugin": {
        "Authors": [
            {
                "Email": "dev@raytolfas.com",
                "Name": "Raytolfas OS"
            }
        ],
        "Id": "Raytolfas",
        "License": "Proprietary",
        "Name": "Raytolfas"
    }
}
WPMETA
fi

echo "[sync] Updating SDDM autologin and Qt6 Breeze theme..."
mkdir -p "${ROOTFS}/etc/sddm.conf.d"
cat << 'EOF' > "${ROOTFS}/etc/sddm.conf.d/autologin.conf"
[Autologin]
User=admin
Session=plasma
Relogin=false

[Theme]
Current=breeze
CursorTheme=Bibata-Modern-Classic
EOF

if [ -d "${ROOTFS}/usr/share/sddm/themes/breeze" ]; then
    cat << 'EOF' > "${ROOTFS}/usr/share/sddm/themes/breeze/theme.conf.user"
[General]
type=image
background=/usr/share/wallpapers/Raytolfas/wallpaper.png
EOF
    rm -rf "${ROOTFS}/usr/share/sddm/themes/Fluent"
    ln -sf breeze "${ROOTFS}/usr/share/sddm/themes/Fluent"
fi

if [ -f "${ROOTFS}/usr/share/wayland-sessions/plasma.desktop" ]; then
    ln -sf plasma.desktop "${ROOTFS}/usr/share/wayland-sessions/plasmawayland.desktop"
fi

echo "[sync] Updating environment and system locale..."
cat << 'EOF' > "${ROOTFS}/etc/environment"
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
QT_QPA_PLATFORM="wayland;xcb"
MANGOHUD=1
LANG="en_US.UTF-8"
LC_ALL="en_US.UTF-8"
LANGUAGE="en_US:en"
EOF
rm -f "${ROOTFS}/etc/profile.d/kwin-env.sh"

cat << 'EOF' > "${ROOTFS}/etc/default/locale"
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
LANGUAGE=en_US:en
EOF
cp -f "${ROOTFS}/etc/default/locale" "${ROOTFS}/etc/locale.conf" 2>/dev/null || true

cat << 'LOCALERC' | tee "${ROOTFS}/etc/skel/.config/plasma-localerc" "${ROOTFS}/home/admin/.config/plasma-localerc" "${ROOTFS}/etc/xdg/plasma-localerc" > /dev/null
[Formats]
LANG=en_US.UTF-8
use24HourClock=true

[Translations]
LANGUAGE=en_US:en
LOCALERC
chown -R 1000:1000 "${ROOTFS}/home/admin/.config/plasma-localerc" 2>/dev/null || true

echo "[sync] Installing Plasma 6 Fluent desktop theme, Fluent-dark icons, and branding..."
FLUENT_KDE_SRC="/var/lib/raytolfas/src-themes/fluent-kde"
FLUENT_ICON_SRC="/var/lib/raytolfas/src-themes/fluent-icons"

if [ -d "${FLUENT_KDE_SRC}" ]; then
    mkdir -p "${ROOTFS}/usr/share/aurorae/themes" "${ROOTFS}/usr/share/color-schemes" "${ROOTFS}/usr/share/plasma/desktoptheme"
    cp -rf "${FLUENT_KDE_SRC}/aurorae/Fluent-round-dark"* "${ROOTFS}/usr/share/aurorae/themes/" 2>/dev/null || true
    cp -rf "${FLUENT_KDE_SRC}/aurorae/Fluent-round-light"* "${ROOTFS}/usr/share/aurorae/themes/" 2>/dev/null || true
    cp -f "${FLUENT_KDE_SRC}/color-schemes/FluentDark.colors" "${ROOTFS}/usr/share/color-schemes/FluentDark.colors"
    cp -f "${FLUENT_KDE_SRC}/color-schemes/FluentLight.colors" "${ROOTFS}/usr/share/color-schemes/FluentLight.colors"

    rm -rf "${ROOTFS}/usr/share/plasma/desktoptheme/Fluent-round-dark" "${ROOTFS}/usr/share/plasma/desktoptheme/Fluent-round-light"
    mkdir -p "${ROOTFS}/usr/share/plasma/desktoptheme/Fluent-round-dark" "${ROOTFS}/usr/share/plasma/desktoptheme/Fluent-round-light"
    cp -rf "${FLUENT_KDE_SRC}/plasma/desktoptheme/Fluent-round/"* "${ROOTFS}/usr/share/plasma/desktoptheme/Fluent-round-dark/"
    cp -f "${FLUENT_KDE_SRC}/color-schemes/FluentDark.colors" "${ROOTFS}/usr/share/plasma/desktoptheme/Fluent-round-dark/colors"

    cp -rf "${FLUENT_KDE_SRC}/plasma/desktoptheme/Fluent-round/"* "${ROOTFS}/usr/share/plasma/desktoptheme/Fluent-round-light/"
    cp -rf "${FLUENT_KDE_SRC}/plasma/desktoptheme/Fluent-round-light/dialogs/"*.svgz "${ROOTFS}/usr/share/plasma/desktoptheme/Fluent-round-light/dialogs/" 2>/dev/null || true
    cp -rf "${FLUENT_KDE_SRC}/plasma/desktoptheme/Fluent-round-light/widgets/"*.svgz "${ROOTFS}/usr/share/plasma/desktoptheme/Fluent-round-light/widgets/" 2>/dev/null || true
    cp -rf "${FLUENT_KDE_SRC}/plasma/desktoptheme/Fluent-round-light/translucent/"* "${ROOTFS}/usr/share/plasma/desktoptheme/Fluent-round-light/translucent/" 2>/dev/null || true
    cp -f "${FLUENT_KDE_SRC}/color-schemes/FluentLight.colors" "${ROOTFS}/usr/share/plasma/desktoptheme/Fluent-round-light/colors"
fi

rm -f "${ROOTFS}/usr/share/plasma/desktoptheme/Fluent-round-dark/icons/start.svgz" \
      "${ROOTFS}/usr/share/plasma/desktoptheme/Fluent-round-light/icons/start.svgz"

python3 - "${ROOTFS}/usr/share/plasma/desktoptheme" << 'PYSCRUB'
import sys, glob, gzip, re

base = sys.argv[1]
style_re = re.compile(r'<style\b[^>]*>.*?</style>|<style\b[^>]*/>', re.DOTALL)

for theme in ("Fluent-round-dark", "Fluent-round-light"):
    for path in glob.glob(f"{base}/{theme}/**/*.svg*", recursive=True):
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

if [ -d "${FLUENT_ICON_SRC}" ] && [ ! -d "${ROOTFS}/usr/share/icons/Fluent-dark" ]; then
    bash "${FLUENT_ICON_SRC}/install.sh" -d "${ROOTFS}/usr/share/icons"
fi

if [ -f "${ROOTFS}/usr/share/icons/Fluent-dark/index.theme" ]; then
    sed -i 's/^Inherits=.*/Inherits=Papirus-Dark,breeze-dark,hicolor/' "${ROOTFS}/usr/share/icons/Fluent-dark/index.theme"
fi
if [ -f "${ROOTFS}/usr/share/icons/Fluent-light/index.theme" ]; then
    sed -i 's/^Inherits=.*/Inherits=Papirus-Light,breeze,hicolor/' "${ROOTFS}/usr/share/icons/Fluent-light/index.theme"
fi
if [ -f "${ROOTFS}/usr/share/icons/Fluent/index.theme" ]; then
    sed -i 's/^Inherits=.*/Inherits=Papirus,breeze,hicolor/' "${ROOTFS}/usr/share/icons/Fluent/index.theme"
fi

for fbase in "${ROOTFS}/usr/share/icons/.Fluent-dark-base" "${ROOTFS}/usr/share/icons/.Fluent-base"; do
    [ -d "${fbase}" ] || continue
    if [ -e "${fbase}/symbolic/status/notification-symbolic.svg" ]; then
        ln -sf notification-symbolic.svg "${fbase}/symbolic/status/notification-inactive-symbolic.svg"
    fi
    if [ -e "${fbase}/symbolic/status/notification-new-symbolic.svg" ]; then
        ln -sf notification-new-symbolic.svg "${fbase}/symbolic/status/notification-active-symbolic.svg"
    fi
    if [ -e "${fbase}/symbolic/status/network-wired-symbolic.svg" ] && [ -d "${fbase}/symbolic/devices" ]; then
        ln -sf ../status/network-wired-symbolic.svg "${fbase}/symbolic/devices/network-wired-symbolic.svg"
    fi
    if [ -e "${fbase}/symbolic/devices/drive-removable-media-usb-symbolic.svg" ]; then
        ln -sf drive-removable-media-usb-symbolic.svg "${fbase}/symbolic/devices/drive-removable-media-symbolic.svg"
    fi
    if [ -e "${fbase}/symbolic/status/arrow-up-tiny-symbolic.svg" ]; then
        ln -sf ../status/arrow-up-tiny-symbolic.svg "${fbase}/symbolic/actions/arrow-up-symbolic.svg"
        ln -sf ../status/arrow-up-tiny-symbolic.svg "${fbase}/symbolic/actions/go-up-symbolic.svg"
        for sz in 16 22 24 32; do
            if [ -d "${fbase}/${sz}/actions" ]; then
                rm -f "${fbase}/${sz}/actions/arrow-up.svg"
                cp -f "${fbase}/symbolic/status/arrow-up-tiny-symbolic.svg" "${fbase}/${sz}/actions/arrow-up.svg"
            fi
        done
    fi
    if [ -e "${fbase}/symbolic/status/arrow-down-tiny-symbolic.svg" ]; then
        ln -sf ../status/arrow-down-tiny-symbolic.svg "${fbase}/symbolic/actions/arrow-down-symbolic.svg"
        ln -sf ../status/arrow-down-tiny-symbolic.svg "${fbase}/symbolic/actions/go-down-symbolic.svg"
        for sz in 16 22 24 32; do
            if [ -d "${fbase}/${sz}/actions" ]; then
                rm -f "${fbase}/${sz}/actions/arrow-down.svg"
                cp -f "${fbase}/symbolic/status/arrow-down-tiny-symbolic.svg" "${fbase}/${sz}/actions/arrow-down.svg"
            fi
        done
    fi
done

if [ -f assets/logo.svg ]; then
    while IFS= read -r existing_start; do
        [ -n "${existing_start}" ] || continue
        rm -f "${existing_start}"
        cp -f assets/logo.svg "${existing_start}"
    done < <(find "${ROOTFS}/usr/share/icons" -maxdepth 5 -name 'start-here*.svg' 2>/dev/null || true)

    for dest in \
        "${ROOTFS}/usr/share/icons/.Fluent-base/scalable/apps/start-here-raytolfas.svg" \
        "${ROOTFS}/usr/share/icons/.Fluent-base/scalable/apps/raytolfas-logo.svg" \
        "${ROOTFS}/usr/share/icons/.Fluent-base/scalable/apps/distributor-logo.svg" \
        "${ROOTFS}/usr/share/icons/.Fluent-dark-base/symbolic/places/start-here-symbolic.svg" \
        "${ROOTFS}/usr/share/icons/.Fluent-base/symbolic/places/start-here-symbolic.svg" \
        "${ROOTFS}/usr/share/icons/hicolor/scalable/apps/start-here-raytolfas.svg" \
        "${ROOTFS}/usr/share/icons/hicolor/scalable/apps/raytolfas-logo.svg" \
        "${ROOTFS}/usr/share/icons/hicolor/scalable/apps/start-here.svg" \
        "${ROOTFS}/usr/share/icons/hicolor/scalable/apps/start-here-kde.svg" \
        "${ROOTFS}/usr/share/icons/hicolor/scalable/apps/distributor-logo.svg" \
        "${ROOTFS}/usr/share/icons/hicolor/scalable/apps/distributor-logo-raytolfas.svg" \
        "${ROOTFS}/usr/share/icons/breeze/apps/48/start-here-kde.svg" \
        "${ROOTFS}/usr/share/icons/breeze-dark/apps/48/start-here-kde.svg" \
        "${ROOTFS}/usr/share/icons/breeze-dark/apps/48/start-here.svg" \
        "${ROOTFS}/usr/share/icons/breeze-dark/apps/48/start-here-raytolfas.svg" \
        "${ROOTFS}/usr/share/icons/Papirus/48x48/places/start-here-kde.svg" \
        "${ROOTFS}/usr/share/icons/Papirus/48x48/places/start-here.svg" \
        "${ROOTFS}/usr/share/icons/Papirus/48x48/places/distributor-logo.svg" \
        "${ROOTFS}/usr/share/icons/Papirus/48x48/places/distributor-logo-raytolfas.svg" \
        "${ROOTFS}/usr/share/icons/Papirus/48x48/apps/raytolfas-logo.svg" \
        "${ROOTFS}/usr/share/icons/Papirus/48x48/apps/start-here-raytolfas.svg" \
        "${ROOTFS}/usr/share/pixmaps/raytolfas-logo.svg" \
        "${ROOTFS}/usr/share/pixmaps/start-here-raytolfas.svg"; do
        mkdir -p "$(dirname "${dest}")"
        rm -f "${dest}"
        cp -f assets/logo.svg "${dest}"
    done
fi

rm -f "${ROOTFS}/usr/share/icons/"*/icon-theme.cache "${ROOTFS}/usr/share/icons/."*/icon-theme.cache 2>/dev/null || true

python3 - << 'PYICONS'
import gzip, os, re, shutil, subprocess

rootfs = "/var/lib/raytolfas/plasma-rootfs"
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

if [ -f assets/logo.png ]; then
    mkdir -p "${ROOTFS}/usr/share/pixmaps" "${ROOTFS}/usr/share/icons/hicolor/512x512/apps"
    cp -f assets/logo.png "${ROOTFS}/usr/share/pixmaps/raytolfas-logo.png"
    cp -f assets/logo.png "${ROOTFS}/usr/share/icons/hicolor/512x512/apps/start-here-raytolfas.png"
    cp -f assets/logo.png "${ROOTFS}/usr/share/icons/hicolor/512x512/apps/raytolfas-logo.png"
    if [ -d "${ROOTFS}/etc/calamares/branding/raytolfas" ]; then
        cp -f assets/logo.png "${ROOTFS}/etc/calamares/branding/raytolfas/logo-white.png"
    fi
    for theme_dir in \
        "${ROOTFS}/usr/share/plasma/look-and-feel/org.raytolfas.light" \
        "${ROOTFS}/usr/share/plasma/look-and-feel/com.github.vinceliuice.Fluent-round-dark" \
        "${ROOTFS}/usr/share/plasma/look-and-feel/org.raytolfas.desktop"; do
        if [ -d "${theme_dir}/contents/splash/images" ]; then
            cp -f assets/logo.png "${theme_dir}/contents/splash/images/logo-white.png"
            if [ -f assets/logo.svg ]; then
                cp -f assets/logo.svg "${theme_dir}/contents/splash/images/logo-white.svg"
            fi
        fi
    done
fi

if [ -f assets/logo.txt ]; then
    mkdir -p "${ROOTFS}/usr/share/fastfetch"
    cp -f assets/logo.txt "${ROOTFS}/usr/share/fastfetch/raytolfas-logo.txt"
    rm -f "${ROOTFS}/usr/share/fastfetch/raytolfas-logo-small.txt"
fi

echo "[sync] Removing Welcome app and syncing Control Center..."
rm -rf "${ROOTFS}/usr/share/raytolfas/welcome" \
    "${ROOTFS}/usr/local/bin/raytolfas-welcome" \
    "${ROOTFS}/etc/skel/.config/autostart/raytolfas-welcome.desktop" \
    "${ROOTFS}/home/admin/.config/autostart/raytolfas-welcome.desktop" \
    "${ROOTFS}/usr/share/applications/raytolfas-welcome.desktop"

mkdir -p "${ROOTFS}/usr/share/raytolfas/control-center"
cp -a apps/control-center/. "${ROOTFS}/usr/share/raytolfas/control-center/"
rm -rf "${ROOTFS}/usr/share/raytolfas/control-center/__pycache__"
chmod +x "${ROOTFS}/usr/share/raytolfas/control-center/main.py"

for app_dir in m1-shell desktop-mode console-mode spotlight; do
    if [ -d "apps/${app_dir}" ]; then
        mkdir -p "${ROOTFS}/usr/share/raytolfas/${app_dir}"
        cp -a "apps/${app_dir}/." "${ROOTFS}/usr/share/raytolfas/${app_dir}/"
        rm -rf "${ROOTFS}/usr/share/raytolfas/${app_dir}/__pycache__"
        chmod +x "${ROOTFS}/usr/share/raytolfas/${app_dir}/main.py"
    fi
done

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
        rm -rf "${target}/logout" "${target}/lockscreen" "${target}/systemdialog" "${target}/components"
        mkdir -p "${target}/splash/images"
        cat << 'SPLASH_QML' > "${target}/splash/Splash.qml"
import QtQuick

Rectangle {
    id: root
    anchors.fill: parent
    color: "#090b10"

    property int stage: 0

    Column {
        anchors.centerIn: parent
        spacing: 24

        Image {
            width: 88
            height: 88
            source: "images/logo-white.png"
            sourceSize.width: 176
            sourceSize.height: 176
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            smooth: true
        }

        Rectangle {
            width: 140
            height: 2
            radius: 1
            color: "#1e2636"
            clip: true
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                width: 44
                height: 2
                radius: 1
                color: "#f1f5f9"

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: true
                    PropertyAnimation { from: -44; to: 140; duration: 1200; easing.type: Easing.InOutQuad }
                }
            }
        }
    }
}
SPLASH_QML
        if [ -f "${target}/defaults" ]; then
            sed -i 's/\r$//' "${target}/defaults" 2>/dev/null || true
            if [ "${t}" = "org.raytolfas.light" ]; then
                sed -i 's/cursorTheme=breeze_cursors/cursorTheme=Bibata-Modern-Classic/g; s/cursorTheme=Fluent-dark-cursors/cursorTheme=Bibata-Modern-Classic/g; s/Theme=Papirus-Dark/Theme=Papirus-Light/g; s/Theme=Fluent-dark/Theme=Papirus-Light/g; s/Theme=Fluent-light/Theme=Papirus-Light/g; s/name=Fluent-round-dark/name=Fluent-round-light/g; s/widgetStyle=kvantum-dark/widgetStyle=Breeze/g; s/floating=1/floating=0/g' "${target}/defaults" 2>/dev/null || true
            else
                sed -i 's/cursorTheme=breeze_cursors/cursorTheme=Bibata-Modern-Classic/g; s/cursorTheme=Fluent-dark-cursors/cursorTheme=Bibata-Modern-Classic/g; s/Theme=Fluent-dark/Theme=Papirus-Dark/g; s/Theme=Fluent-light/Theme=Papirus-Dark/g; s/widgetStyle=kvantum-dark/widgetStyle=Breeze/g; s/floating=1/floating=0/g' "${target}/defaults" 2>/dev/null || true
            fi
        fi
    fi
done

for dt_id in Fluent-round-dark Fluent-round-light; do
    if [ -d "${ROOTFS}/usr/share/plasma/desktoptheme/${dt_id}" ]; then
        rm -f "${ROOTFS}/usr/share/plasma/desktoptheme/${dt_id}/metadata.desktop"
        cat << DT_META > "${ROOTFS}/usr/share/plasma/desktoptheme/${dt_id}/metadata.json"
{
    "KPlugin": {
        "Authors": [
            {
                "Email": "dev@raytolfas.com",
                "Name": "Raytolfas OS"
            }
        ],
        "Category": "",
        "Description": "${dt_id} desktop style",
        "EnabledByDefault": true,
        "Id": "${dt_id}",
        "License": "LGPL",
        "Name": "${dt_id}",
        "Version": "6.0",
        "Website": "https://os.raytolfas.com"
    },
    "X-Plasma-API-Minimum-Version": "6.0"
}
DT_META
    fi
done

cat << 'KDEGLOBALS_EOF' | tee "${ROOTFS}/etc/xdg/kdeglobals" "${ROOTFS}/etc/skel/.config/kdeglobals" "${ROOTFS}/home/admin/.config/kdeglobals" > /dev/null
[KScreen]
ScaleFactor=1

[General]
ColorScheme=FluentDark
Name=Fluent Dark
font=Noto Sans,11,-1,5,50,0,0,0,0,0
menuFont=Noto Sans,11,-1,5,50,0,0,0,0,0
smallestReadableFont=Noto Sans,9,-1,5,50,0,0,0,0,0
toolBarFont=Noto Sans,11,-1,5,50,0,0,0,0,0

[Icons]
Theme=Papirus-Dark

[KDE]
LookAndFeelPackage=org.raytolfas.desktop
SingleClick=false
ShowDeleteCommand=true
AnimationDurationFactor=0.85

[KDE-Global-Accelerators]
AnimationDurationFactor=0.85
KDEGLOBALS_EOF
chown 1000:1000 "${ROOTFS}/home/admin/.config/kdeglobals" 2>/dev/null || true

cat << 'BALOO_EOF' | tee "${ROOTFS}/etc/xdg/baloofilerc" "${ROOTFS}/etc/skel/.config/baloofilerc" "${ROOTFS}/home/admin/.config/baloofilerc" > /dev/null
[Basic Settings]
Indexing-Enabled=false
BALOO_EOF
chown -R 1000:1000 "${ROOTFS}/home/admin/.config/baloofilerc" 2>/dev/null || true
rm -f "${ROOTFS}/etc/xdg/autostart/baloo_file.desktop"

mkdir -p "${ROOTFS}/etc/gtk-3.0" "${ROOTFS}/etc/skel/.config/gtk-3.0" "${ROOTFS}/etc/skel/.config/gtk-4.0" "${ROOTFS}/home/admin/.config/gtk-3.0" "${ROOTFS}/home/admin/.config/gtk-4.0"
cat << 'GTK_INI' | tee "${ROOTFS}/etc/gtk-3.0/settings.ini" "${ROOTFS}/etc/skel/.config/gtk-3.0/settings.ini" "${ROOTFS}/etc/skel/.config/gtk-4.0/settings.ini" "${ROOTFS}/home/admin/.config/gtk-3.0/settings.ini" "${ROOTFS}/home/admin/.config/gtk-4.0/settings.ini" > /dev/null
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Breeze-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-font-name=Noto Sans 11
GTK_INI
chown -R 1000:1000 "${ROOTFS}/home/admin/.config/gtk-3.0" "${ROOTFS}/home/admin/.config/gtk-4.0" 2>/dev/null || true

for pdir in "${ROOTFS}/usr/share/icons/Papirus" "${ROOTFS}/usr/share/icons/Papirus-Dark" "${ROOTFS}/usr/share/icons/Papirus-Light"; do
    [ -d "${pdir}" ] || continue
    if [ -d "${pdir}/48x48/apps" ] && [ -e "${pdir}/48x48/apps/plasmadiscover.svg" ]; then
        ln -sf plasmadiscover.svg "${pdir}/48x48/apps/org.kde.discover.svg"
    fi
    if [ -d "${pdir}/symbolic/status" ] && [ -e "${pdir}/symbolic/status/notification-symbolic.svg" ]; then
        ln -sf notification-symbolic.svg "${pdir}/symbolic/status/notification-inactive-symbolic.svg"
        ln -sf notification-new-symbolic.svg "${pdir}/symbolic/status/notification-active-symbolic.svg"
    fi
done

if [ -f "${ROOTFS}/usr/share/applications/raytolfas-android.desktop" ]; then
    sed -i 's/^Icon=.*/Icon=waydroid/' "${ROOTFS}/usr/share/applications/raytolfas-android.desktop"
fi

if [ -f assets/logo.png ]; then
    mkdir -p "${ROOTFS}/var/lib/AccountsService/icons" "${ROOTFS}/var/lib/AccountsService/users"
    cp -f assets/logo.png "${ROOTFS}/tmp/avatar-src.png"
    chroot "${ROOTFS}" python3 - << 'PYAVATAR'
import os
os.environ["QT_QPA_PLATFORM"] = "offscreen"
from PyQt6.QtGui import QGuiApplication, QImage, QPainter, QColor, QPen
from PyQt6.QtCore import Qt, QRectF

app = QGuiApplication([])
canvas = QImage(256, 256, QImage.Format.Format_ARGB32_Premultiplied)
canvas.fill(Qt.GlobalColor.transparent)

p = QPainter(canvas)
p.setRenderHint(QPainter.RenderHint.Antialiasing, True)
p.setRenderHint(QPainter.RenderHint.SmoothPixmapTransform, True)
p.setBrush(QColor("#141824"))
p.setPen(QPen(QColor("#2c354d"), 4))
p.drawEllipse(QRectF(4, 4, 248, 248))

logo = QImage("/tmp/avatar-src.png")
if not logo.isNull():
    scaled = logo.scaled(144, 144, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation)
    x = (256 - scaled.width()) // 2
    y = (256 - scaled.height()) // 2
    p.drawImage(x, y, scaled)
p.end()

for out in ("/etc/skel/.face.icon", "/home/admin/.face.icon", "/var/lib/AccountsService/icons/admin"):
    canvas.save(out, "PNG")
PYAVATAR
    rm -f "${ROOTFS}/tmp/avatar-src.png"
    ln -sf .face.icon "${ROOTFS}/etc/skel/.face"
    ln -sf .face.icon "${ROOTFS}/home/admin/.face"
    chown -h 1000:1000 "${ROOTFS}/home/admin/.face.icon" "${ROOTFS}/home/admin/.face" 2>/dev/null || true
    cat << 'ACCT_USER' > "${ROOTFS}/var/lib/AccountsService/users/admin"
[User]
Icon=/var/lib/AccountsService/icons/admin
SystemAccount=false
ACCT_USER
fi

for lnf_id in org.raytolfas.desktop org.raytolfas.light com.github.vinceliuice.Fluent-round-dark; do
    if [ -d "${ROOTFS}/usr/share/plasma/look-and-feel/${lnf_id}" ]; then
        lnf_name="System Dark"
        [ "${lnf_id}" = "org.raytolfas.light" ] && lnf_name="System Light"
        [ "${lnf_id}" = "com.github.vinceliuice.Fluent-round-dark" ] && lnf_name="Fluent Round Dark"
        cat << LNF_META > "${ROOTFS}/usr/share/plasma/look-and-feel/${lnf_id}/metadata.json"
{
    "KPlugin": {
        "Authors": [
            {
                "Email": "dev@raytolfas.com",
                "Name": "Raytolfas OS"
            }
        ],
        "Description": "${lnf_name}",
        "Id": "${lnf_id}",
        "Name": "${lnf_name}",
        "ServiceTypes": [
            "Plasma/LookAndFeel"
        ],
        "Version": "6.0",
        "Website": "https://os.raytolfas.com"
    },
    "X-Plasma-API-Minimum-Version": "6.0"
}
LNF_META
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
mkdir -p "${ROOTFS}/usr/share/applications" "${ROOTFS}/etc/skel/Desktop" "${ROOTFS}/home/admin/Desktop"
cat << 'CALDESK' > "${ROOTFS}/usr/share/applications/calamares.desktop"
[Desktop Entry]
Type=Application
Version=1.0
Name=Install Raytolfas OS
GenericName=System Installer
Comment=Install the operating system to disk
Exec=/usr/local/bin/raytolfas-install
Icon=start-here-raytolfas
Terminal=false
StartupNotify=true
Categories=Qt;System;
CALDESK
chmod 0644 "${ROOTFS}/usr/share/applications/calamares.desktop"
cp -f "${ROOTFS}/usr/share/applications/calamares.desktop" "${ROOTFS}/etc/skel/Desktop/calamares.desktop"
cp -f "${ROOTFS}/usr/share/applications/calamares.desktop" "${ROOTFS}/home/admin/Desktop/calamares.desktop"
chmod 0755 "${ROOTFS}/etc/skel/Desktop/calamares.desktop"
chmod 0755 "${ROOTFS}/home/admin/Desktop/calamares.desktop"
chown 1000:1000 "${ROOTFS}/home/admin/Desktop/calamares.desktop" 2>/dev/null || true

echo "[sync] Syncing kernel symlinks in rootfs /boot..."
mkdir -p "${ROOTFS}/boot"
TARGET_VMLINUZ="$(ls -1t "${ROOTFS}/boot/vmlinuz-"*cachyos* "${ROOTFS}/boot/vmlinuz-"*-generic 2>/dev/null | head -n 1 || true)"
if [ -n "${TARGET_VMLINUZ}" ] && [ -f "${TARGET_VMLINUZ}" ]; then
    KERNEL_NAME="$(basename "${TARGET_VMLINUZ}")"
    VERSION_SUFFIX="${KERNEL_NAME#vmlinuz-}"
    ln -sf "${KERNEL_NAME}" "${ROOTFS}/boot/vmlinuz"
    ln -sf "boot/${KERNEL_NAME}" "${ROOTFS}/vmlinuz"
    if [ -f "${ROOTFS}/boot/initrd.img-${VERSION_SUFFIX}" ]; then
        ln -sf "initrd.img-${VERSION_SUFFIX}" "${ROOTFS}/boot/initrd.img"
        ln -sf "boot/initrd.img-${VERSION_SUFFIX}" "${ROOTFS}/initrd.img"
    fi
fi

echo "[sync] Applying Waydroid network patch..."
WAYDROID_NET="${ROOTFS}/usr/lib/waydroid/data/scripts/waydroid-net.sh"
if [ -f "$WAYDROID_NET" ]; then
    sed -i 's/LXC_USE_NFT="false"/LXC_USE_NFT="true"/g' "$WAYDROID_NET"
    sed -i 's/command -v iptables-legacy/command -v iptables-nft/g' "$WAYDROID_NET"
    sed -i 's/command -v ip6tables-legacy/command -v ip6tables-nft/g' "$WAYDROID_NET"
    sed -i 's/set -e/set +e/g' "$WAYDROID_NET"
    sed -i 's/FAILED=1/FAILED=0/g' "$WAYDROID_NET"
fi

echo "[sync] Syncing tools, snapshot managers, and desktop entries..."
for tool in raytolfas-control-center raytolfas-proton raytolfas-proton-update raytolfas-android raytolfas-apk-install raytolfas-waydroid-setup raytolfas-waydroid-net-fix prime-run raytolfas-mobile-test raytolfas-rqb-runner raytolfas-upgrade-iso btrfs-auto-snapshot limine-snapper-ext ananicy-cpp raytolfas-turbo raytolfas-dev raytolfas-bench raytolfas-appimage raytolfas-desktop-mode raytolfas-console-mode raytolfas-spotlight raytolfas-clean raytolfas-ri-growpart starship; do
    if [ -f "scripts/tools/${tool}" ]; then
        cp -f "scripts/tools/${tool}" "${ROOTFS}/usr/local/bin/${tool}"
        cp -f "scripts/tools/${tool}" "${ROOTFS}/usr/bin/${tool}"
        chmod 0755 "${ROOTFS}/usr/local/bin/${tool}" "${ROOTFS}/usr/bin/${tool}"
    fi
done
rm -f "${ROOTFS}/usr/local/bin/raytolfas-nvidia-setup" "${ROOTFS}/usr/bin/raytolfas-nvidia-setup"

if [ -f config/mobile/plasmamobilerc ]; then
    mkdir -p "${ROOTFS}/etc/xdg" "${ROOTFS}/etc/skel/.config" "${ROOTFS}/home/admin/.config"
    cp -f config/mobile/plasmamobilerc "${ROOTFS}/etc/xdg/plasmamobilerc"
    cp -f config/mobile/plasmamobilerc "${ROOTFS}/etc/skel/.config/plasmamobilerc"
    cp -f config/mobile/plasmamobilerc "${ROOTFS}/home/admin/.config/plasmamobilerc"
    chown 1000:1000 "${ROOTFS}/home/admin/.config/plasmamobilerc" 2>/dev/null || true
fi

if [ -f config/sessions/raytolfas-console.desktop ]; then
    mkdir -p "${ROOTFS}/usr/share/wayland-sessions"
    cp -f config/sessions/raytolfas-console.desktop "${ROOTFS}/usr/share/wayland-sessions/raytolfas-console.desktop"
    chmod 0644 "${ROOTFS}/usr/share/wayland-sessions/raytolfas-console.desktop"
fi

for desk_entry in raytolfas-control-center.desktop raytolfas-turbo.desktop raytolfas-console-mode.desktop raytolfas-desktop-mode.desktop raytolfas-spotlight.desktop; do
    if [ -f "config/applications/${desk_entry}" ]; then
        mkdir -p "${ROOTFS}/usr/share/applications"
        cp -f "config/applications/${desk_entry}" "${ROOTFS}/usr/share/applications/${desk_entry}"
        chmod 0644 "${ROOTFS}/usr/share/applications/${desk_entry}"
    fi
done

if [ -f config/kde/kcminputrc ]; then
    mkdir -p "${ROOTFS}/etc/xdg" "${ROOTFS}/etc/skel/.config" "${ROOTFS}/home/admin/.config"
    cp -f config/kde/kcminputrc "${ROOTFS}/etc/xdg/kcminputrc"
    cp -f config/kde/kcminputrc "${ROOTFS}/etc/skel/.config/kcminputrc"
    cp -f config/kde/kcminputrc "${ROOTFS}/home/admin/.config/kcminputrc"
    chown -R 1000:1000 "${ROOTFS}/home/admin/.config/kcminputrc" 2>/dev/null || true
fi

if [ -f config/icons/default-index.theme ]; then
    mkdir -p "${ROOTFS}/usr/share/icons/default"
    cp -f config/icons/default-index.theme "${ROOTFS}/usr/share/icons/default/index.theme"
    chmod 0644 "${ROOTFS}/usr/share/icons/default/index.theme"
fi

if [ -f config/starship/starship.toml ]; then
    mkdir -p "${ROOTFS}/etc" "${ROOTFS}/etc/skel/.config" "${ROOTFS}/home/admin/.config"
    cp -f config/starship/starship.toml "${ROOTFS}/etc/starship.toml"
    cp -f config/starship/starship.toml "${ROOTFS}/etc/skel/.config/starship.toml"
    cp -f config/starship/starship.toml "${ROOTFS}/home/admin/.config/starship.toml"
    chmod 0644 "${ROOTFS}/etc/starship.toml" "${ROOTFS}/etc/skel/.config/starship.toml" "${ROOTFS}/home/admin/.config/starship.toml"
    chown -R 1000:1000 "${ROOTFS}/home/admin/.config/starship.toml" 2>/dev/null || true
fi

if ! grep -q "starship init bash" "${ROOTFS}/etc/bash.bashrc" 2>/dev/null; then
    cat << 'STARSHIP_INIT' >> "${ROOTFS}/etc/bash.bashrc"
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi
STARSHIP_INIT
fi

if [ -f config/udev/70-game-controllers.rules ]; then
    mkdir -p "${ROOTFS}/etc/udev/rules.d"
    cp -f config/udev/70-game-controllers.rules "${ROOTFS}/etc/udev/rules.d/70-game-controllers.rules"
    chmod 0644 "${ROOTFS}/etc/udev/rules.d/70-game-controllers.rules"
fi

if [ -f config/vkbasalt/vkBasalt.conf ]; then
    mkdir -p "${ROOTFS}/etc" "${ROOTFS}/etc/skel/.config/vkBasalt" "${ROOTFS}/home/admin/.config/vkBasalt"
    cp -f config/vkbasalt/vkBasalt.conf "${ROOTFS}/etc/vkBasalt.conf"
    cp -f config/vkbasalt/vkBasalt.conf "${ROOTFS}/etc/skel/.config/vkBasalt/vkBasalt.conf"
    cp -f config/vkbasalt/vkBasalt.conf "${ROOTFS}/home/admin/.config/vkBasalt/vkBasalt.conf"
    chmod 0644 "${ROOTFS}/etc/vkBasalt.conf" "${ROOTFS}/etc/skel/.config/vkBasalt/vkBasalt.conf" "${ROOTFS}/home/admin/.config/vkBasalt/vkBasalt.conf"
    chown -R 1000:1000 "${ROOTFS}/home/admin/.config/vkBasalt" 2>/dev/null || true
fi

if [ -f config/syntax/rayquiro.xml ]; then
    mkdir -p "${ROOTFS}/usr/share/org.kde.syntax-highlighting/syntax"
    cp -f config/syntax/rayquiro.xml "${ROOTFS}/usr/share/org.kde.syntax-highlighting/syntax/rayquiro.xml"
    chmod 0644 "${ROOTFS}/usr/share/org.kde.syntax-highlighting/syntax/rayquiro.xml"
fi

if [ -f config/firefox/syspref.js ]; then
    mkdir -p "${ROOTFS}/etc/firefox"
    cp -f config/firefox/syspref.js "${ROOTFS}/etc/firefox/syspref.js"
    chmod 0644 "${ROOTFS}/etc/firefox/syspref.js"
fi

if [ -f config/applications/raytolfas-turbo.desktop ]; then
    mkdir -p "${ROOTFS}/usr/share/applications"
    cp -f config/applications/raytolfas-turbo.desktop "${ROOTFS}/usr/share/applications/raytolfas-turbo.desktop"
    chmod 0644 "${ROOTFS}/usr/share/applications/raytolfas-turbo.desktop"
fi

if [ -f config/apt/80-btrfs-auto-snapshot ]; then
    mkdir -p "${ROOTFS}/etc/apt/apt.conf.d"
    cp -f config/apt/80-btrfs-auto-snapshot "${ROOTFS}/etc/apt/apt.conf.d/80-btrfs-auto-snapshot"
    chmod 0644 "${ROOTFS}/etc/apt/apt.conf.d/80-btrfs-auto-snapshot"
fi

if [ -d config/servicemenus ]; then
    rm -rf "${ROOTFS}/usr/share/kservices5/ServiceMenus"
    mkdir -p "${ROOTFS}/usr/share/kio/servicemenus"
    cp -f config/servicemenus/*.desktop "${ROOTFS}/usr/share/kio/servicemenus/"
    chmod 0755 "${ROOTFS}/usr/share/kio/servicemenus/"*.desktop
fi

if [ -d config/konsole ]; then
    mkdir -p "${ROOTFS}/usr/share/konsole" "${ROOTFS}/etc/xdg" "${ROOTFS}/etc/skel/.config" "${ROOTFS}/home/admin/.config"
    cp -f config/konsole/Raytolfas.profile "${ROOTFS}/usr/share/konsole/Raytolfas.profile"
    cp -f config/konsole/RaytolfasDark.colorscheme "${ROOTFS}/usr/share/konsole/RaytolfasDark.colorscheme"
    cp -f config/konsole/konsolerc "${ROOTFS}/etc/xdg/konsolerc"
    cp -f config/konsole/konsolerc "${ROOTFS}/etc/skel/.config/konsolerc"
    cp -f config/konsole/konsolerc "${ROOTFS}/home/admin/.config/konsolerc"
    chmod 0644 "${ROOTFS}/usr/share/konsole/Raytolfas.profile" "${ROOTFS}/usr/share/konsole/RaytolfasDark.colorscheme"
    chmod 0644 "${ROOTFS}/etc/xdg/konsolerc" "${ROOTFS}/etc/skel/.config/konsolerc" "${ROOTFS}/home/admin/.config/konsolerc"
    chown -R 1000:1000 "${ROOTFS}/home/admin/.config/konsolerc" 2>/dev/null || true
fi

if [ -d config/ananicy.d ]; then
    mkdir -p "${ROOTFS}/etc/ananicy.d"
    cp -rf config/ananicy.d/* "${ROOTFS}/etc/ananicy.d/"
fi

if [ -f config/systemd/ananicy-cpp.service ]; then
    mkdir -p "${ROOTFS}/etc/systemd/system" "${ROOTFS}/etc/systemd/system/multi-user.target.wants"
    cp -f config/systemd/ananicy-cpp.service "${ROOTFS}/etc/systemd/system/ananicy-cpp.service"
    chmod 0644 "${ROOTFS}/etc/systemd/system/ananicy-cpp.service"
    ln -sf "/etc/systemd/system/ananicy-cpp.service" "${ROOTFS}/etc/systemd/system/multi-user.target.wants/ananicy-cpp.service"
fi

echo "[sync] Syncing system optimizations, audio latency and gaming configs..."
mkdir -p "${ROOTFS}/etc/sysctl.d" "${ROOTFS}/etc/security/limits.d" "${ROOTFS}/etc/pipewire/pipewire.conf.d" "${ROOTFS}/etc/udev/hwdb.d" "${ROOTFS}/etc/udev/rules.d"
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
if [ -f config/udev/60-ioschedulers.rules ]; then
    cp -f config/udev/60-ioschedulers.rules "${ROOTFS}/etc/udev/rules.d/60-ioschedulers.rules"
    chmod 0644 "${ROOTFS}/etc/udev/rules.d/60-ioschedulers.rules"
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

if [ -f "${ROOTFS}/usr/share/applications/org.kde.systemsettings.desktop" ] && [ ! -e "${ROOTFS}/usr/share/applications/systemsettings.desktop" ]; then
    ln -sf org.kde.systemsettings.desktop "${ROOTFS}/usr/share/applications/systemsettings.desktop"
fi
if [ -f "${ROOTFS}/usr/share/applications/systemsettings.desktop" ] && [ ! -e "${ROOTFS}/usr/share/applications/org.kde.systemsettings.desktop" ]; then
    ln -sf systemsettings.desktop "${ROOTFS}/usr/share/applications/org.kde.systemsettings.desktop"
fi

for hidden_desk in kdesystemsettings.desktop org.kde.kuserfeedback-console.desktop org.kde.drkonqi.coredump.gui.desktop raytolfas-wine.desktop raytolfas-apk.desktop; do
    if [ -f "${ROOTFS}/usr/share/applications/${hidden_desk}" ]; then
        if grep -q '^NoDisplay=' "${ROOTFS}/usr/share/applications/${hidden_desk}"; then
            sed -i 's/^NoDisplay=.*/NoDisplay=true/' "${ROOTFS}/usr/share/applications/${hidden_desk}"
        else
            echo "NoDisplay=true" >> "${ROOTFS}/usr/share/applications/${hidden_desk}"
        fi
    fi
done

echo "[sync] Configuring VM display auto-resize and guest Wayland helpers..."
mkdir -p "${ROOTFS}/etc/systemd/system/virtualbox-guest-utils.service.d" "${ROOTFS}/etc/systemd/system/multi-user.target.wants" "${ROOTFS}/etc/systemd/system/sockets.target.wants" "${ROOTFS}/etc/xdg/autostart"
cat << 'VBOX_DROPIN' > "${ROOTFS}/etc/systemd/system/virtualbox-guest-utils.service.d/override.conf"
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
chmod 0644 "${ROOTFS}/etc/systemd/system/virtualbox-guest-utils.service.d/override.conf"
if [ -f "${ROOTFS}/usr/lib/systemd/system/virtualbox-guest-utils.service" ]; then
    ln -sf /usr/lib/systemd/system/virtualbox-guest-utils.service "${ROOTFS}/etc/systemd/system/multi-user.target.wants/virtualbox-guest-utils.service"
fi
if [ -f "${ROOTFS}/usr/lib/systemd/system/spice-vdagentd.socket" ]; then
    ln -sf /usr/lib/systemd/system/spice-vdagentd.socket "${ROOTFS}/etc/systemd/system/sockets.target.wants/spice-vdagentd.socket"
fi

cat << 'VMSESS' > "${ROOTFS}/usr/local/bin/raytolfas-vm-session"
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
chmod 0755 "${ROOTFS}/usr/local/bin/raytolfas-vm-session"

cat << 'VMAUTO' > "${ROOTFS}/etc/xdg/autostart/raytolfas-vm-session.desktop"
[Desktop Entry]
Type=Application
Name=VM Guest Session Helper
Exec=/usr/local/bin/raytolfas-vm-session
Terminal=false
NoDisplay=true
X-KDE-autostart-phase=1
VMAUTO
chmod 0644 "${ROOTFS}/etc/xdg/autostart/raytolfas-vm-session.desktop"

find "${ROOTFS}/etc/xdg" "${ROOTFS}/etc/skel/.config" "${ROOTFS}/home/admin/.config" -maxdepth 2 -type f -exec sed -i 's/\r$//' {} + 2>/dev/null || true

echo "[sync] Syncing udisks2 mount options and MangoHud configuration..."
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
rm -f "${ROOTFS}/etc/systemd/system/raytolfas-zram.service" "${ROOTFS}/etc/systemd/system/basic.target.wants/raytolfas-zram.service"
if [ -f config/zram/zramswap ]; then
    mkdir -p "${ROOTFS}/etc/default"
    cp -f config/zram/zramswap "${ROOTFS}/etc/default/zramswap"
    chmod 0644 "${ROOTFS}/etc/default/zramswap"
fi

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

echo "[sync] Updating mimeinfo and hwdb cache..."
if which update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${ROOTFS}/usr/share/applications" 2>/dev/null || true
fi
if which update-mime-database >/dev/null 2>&1; then
    update-mime-database "${ROOTFS}/usr/share/mime" 2>/dev/null || true
fi
if [ -d "${ROOTFS}/etc" ]; then
    chroot "${ROOTFS}" systemd-hwdb update 2>/dev/null || true
    chroot "${ROOTFS}" systemctl mask whoopsie.service apport.service kerneloops.service systemd-pstore.service apt-daily.service apt-daily.timer apt-daily-upgrade.service apt-daily-upgrade.timer kde-baloo.service 2>/dev/null || true
    rm -rf "${ROOTFS}/var/lib/apt/lists/"* "${ROOTFS}/tmp/"* "${ROOTFS}/var/tmp/"* 2>/dev/null || true
fi

echo "[sync] Completed successfully!"
