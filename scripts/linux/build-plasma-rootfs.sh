#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
BUILD_DIR="/var/lib/raytolfas/plasma-rootfs"
CACHE_DIR="/var/cache/raytolfas/plasma-base"

echo "[plasma-rootfs] Starting Raytolfas OS D1 RootFS build in ${BUILD_DIR}..."

sudo mkdir -p "${BUILD_DIR}"
sudo mkdir -p "/var/cache/raytolfas"
mkdir -p "${REPO_ROOT}/build"

if [ ! -f "${CACHE_DIR}/.debootstrap_done" ]; then
    echo "[plasma-rootfs] Running initial debootstrap (Ubuntu 24.04 Noble minbase)..."
    sudo rm -rf "${CACHE_DIR}"
    sudo mkdir -p "${CACHE_DIR}"
    sudo debootstrap --arch=amd64 --variant=minbase \
        --include=systemd,systemd-sysv,dbus,udev,locales,sudo,ca-certificates,curl,wget,gnupg,iproute2,net-tools,librsvg2-bin \
        noble "${CACHE_DIR}" http://archive.ubuntu.com/ubuntu/
    sudo touch "${CACHE_DIR}/.debootstrap_done"
fi

echo "[plasma-rootfs] Syncing base environment to build directory..."
sudo rm -rf "${BUILD_DIR}"
sudo mkdir -p "${BUILD_DIR}"
sudo cp -a "${CACHE_DIR}/." "${BUILD_DIR}/"

cat << 'EOF' | sudo tee "${BUILD_DIR}/etc/apt/sources.list" > /dev/null
deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu noble-security main restricted universe multiverse
EOF

sudo install -d -m 0755 "${BUILD_DIR}/etc/apt/keyrings"
sudo install -d -m 0755 "${BUILD_DIR}/etc/apt/preferences.d"
sudo install -d -m 0755 "${BUILD_DIR}/etc/apt/sources.list.d"

curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg | gpg --dearmor | sudo tee "${BUILD_DIR}/etc/apt/keyrings/packages.mozilla.org.gpg" > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.gpg] https://packages.mozilla.org/apt mozilla main" | sudo tee "${BUILD_DIR}/etc/apt/sources.list.d/mozilla.list" > /dev/null

cat << 'MOZPIN' | sudo tee "${BUILD_DIR}/etc/apt/preferences.d/mozilla" > /dev/null
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
MOZPIN

curl -fsSL https://repo.waydro.id/waydroid.gpg | gpg --dearmor | sudo tee "${BUILD_DIR}/etc/apt/keyrings/waydroid.gpg" > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/waydroid.gpg] https://repo.waydro.id/ noble main" | sudo tee "${BUILD_DIR}/etc/apt/sources.list.d/waydroid.list" > /dev/null

sudo cp -L /etc/resolv.conf "${BUILD_DIR}/etc/resolv.conf"

sudo mount --bind /dev "${BUILD_DIR}/dev"
sudo mount --bind /dev/pts "${BUILD_DIR}/dev/pts"
sudo mount -t proc proc "${BUILD_DIR}/proc"
sudo mount -t sysfs sysfs "${BUILD_DIR}/sys"

cleanup() {
    sudo umount "${BUILD_DIR}/sys" 2>/dev/null || true
    sudo umount "${BUILD_DIR}/proc" 2>/dev/null || true
    sudo umount "${BUILD_DIR}/dev/pts" 2>/dev/null || true
    sudo umount "${BUILD_DIR}/dev" 2>/dev/null || true
}
trap cleanup EXIT

echo "[plasma-rootfs] Installing KDE Plasma, Calamares, Wine/Proton, Waydroid stack inside chroot..."
sudo chroot "${BUILD_DIR}" /bin/bash << 'CHROOT_END'
export DEBIAN_FRONTEND=noninteractive
apt-get update

apt-get install -y --no-install-recommends \
    plasma-desktop \
    kwin-wayland \
    plasma-workspace-wayland \
    xwayland \
    sddm \
    sddm-theme-breeze \
    konsole \
    dolphin \
    kwrite \
    plasma-systemmonitor \
    plasma-pa \
    plasma-nm \
    kcalc \
    ark \
    pipewire \
    pipewire-alsa \
    pipewire-audio \
    pipewire-pulse \
    pipewire-jack \
    wireplumber \
    alsa-utils \
    alsa-ucm-conf \
    alsa-topology-conf \
    libasound2-plugins \
    pulseaudio-utils \
    gstreamer1.0-pipewire \
    rtkit \
    network-manager \
    dhcpcd5 \
    isc-dhcp-client \
    ethtool \
    ifupdown \
    linux-firmware \
    mesa-vulkan-drivers \
    mesa-va-drivers \
    mesa-utils \
    fonts-noto-core \
    fonts-noto-cjk \
    fonts-dejavu-core \
    fonts-liberation2 \
    fonts-roboto \
    pciutils \
    usbutils \
    kio-extras \
    plasma-widgets-addons \
    haruna \
    vlc \
    papirus-icon-theme \
    virtualbox-guest-utils \
    spice-vdagent \
    firefox \
    firefox-l10n-ru \
    firefox-l10n-uk \
    language-pack-en \
    language-pack-ru \
    language-pack-uk \
    language-pack-kde-ru \
    language-pack-kde-uk \
    calamares \
    calamares-settings-ubuntu-common \
    libkpmcore12 \
    parted \
    dosfstools \
    e2fsprogs \
    btrfs-progs \
    squashfs-tools \
    rsync \
    wine \
    wine64 \
    winetricks \
    libvulkan1 \
    vulkan-tools \
    waydroid \
    lxc \
    python3 \
    python3-pip \
    git \
    curl \
    wget \
    librsvg2-bin \
    udisks2 \
    gvfs \
    gvfs-backends \
    udev \
    plymouth \
    plymouth-themes \
    flatpak \
    plasma-discover \
    plasma-discover-backend-flatpak \
    systemsettings \
    kscreen \
    kinfocenter \
    powerdevil \
    kde-config-screenlocker \
    kde-config-sddm \
    kde-config-gtk-style \
    kgamma5 \
    bluedevil \
    kwin-addons \
    pkexec \
    policykit-1 \
    polkitd \
    polkit-kde-agent-1 \
    ntfs-3g \
    exfat-fuse \
    exfatprogs \
    upower \
    acpi \
    acpid \
    brightnessctl \
    wpasupplicant \
    wireless-tools \
    wireless-regdb \
    rfkill \
    ca-certificates \
    thermald \
    cpufrequtils \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    intel-media-va-driver-non-free \
    v4l-utils \
    p7zip-full \
    unrar-free \
    zip \
    unzip \
    mpv \
    zram-tools \
    intel-microcode \
    amd64-microcode \
    kamoso \
    qml-qt6 \
    qmlscene-qt6 \
    python3-pyqt6 \
    qt6-wayland \
    qml6-module-qtquick \
    qml6-module-qtquick-controls \
    qml6-module-qtquick-layouts \
    qml6-module-qtquick-window \
    qml6-module-qtquick-templates \
    qml6-module-qtqml-workerscript \
    fdisk \
    gdisk

locale-gen en_US.UTF-8 ru_RU.UTF-8 uk_UA.UTF-8
update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

chmod 4755 /usr/bin/pkexec 2>/dev/null || true

ln -sf /usr/bin/ntfs-3g /usr/sbin/mount.ntfs 2>/dev/null || true

mkdir -p /etc/systemd/system/multi-user.target.wants
mkdir -p /etc/systemd/system/network-online.target.wants
ln -sf /lib/systemd/system/NetworkManager.service \
    /etc/systemd/system/multi-user.target.wants/NetworkManager.service 2>/dev/null || true
ln -sf /lib/systemd/system/NetworkManager-dispatcher.service \
    /etc/systemd/system/dbus-org.freedesktop.nm-dispatcher.service 2>/dev/null || true
ln -sf /lib/systemd/system/wpa_supplicant.service \
    /etc/systemd/system/multi-user.target.wants/wpa_supplicant.service 2>/dev/null || true
ln -sf /lib/systemd/system/upower.service \
    /etc/systemd/system/multi-user.target.wants/upower.service 2>/dev/null || true
ln -sf /lib/systemd/system/acpid.service \
    /etc/systemd/system/multi-user.target.wants/acpid.service 2>/dev/null || true

cat >> /etc/modules <<'MODS'
r8169
r8168
e1000e
igb
ixgbe
atl1c
atl2
forcedeth
tg3
snd_hda_intel
snd_hda_codec_realtek
snd_hda_codec_hdmi
snd_hda_codec_generic
iwlwifi
cfg80211
mac80211
MODS

mkdir -p /etc/systemd/user/default.target.wants
mkdir -p /etc/systemd/user/sockets.target.wants
ln -sf /usr/lib/systemd/user/pipewire.service /etc/systemd/user/default.target.wants/pipewire.service 2>/dev/null || true
ln -sf /usr/lib/systemd/user/wireplumber.service /etc/systemd/user/default.target.wants/wireplumber.service 2>/dev/null || true
ln -sf /usr/lib/systemd/user/pipewire-pulse.service /etc/systemd/user/default.target.wants/pipewire-pulse.service 2>/dev/null || true
ln -sf /usr/lib/systemd/user/pipewire.socket /etc/systemd/user/sockets.target.wants/pipewire.socket 2>/dev/null || true
ln -sf /usr/lib/systemd/user/pipewire-pulse.socket /etc/systemd/user/sockets.target.wants/pipewire-pulse.socket 2>/dev/null || true

mkdir -p /etc/wireplumber/wireplumber.conf.d
cat > /etc/wireplumber/wireplumber.conf.d/10-alsa-policy.conf <<'WPCONF'
monitor.alsa.rules = [
  {
    matches = [ { node.name = "~alsa_*" } ]
    actions = {
      update-props = {
        api.alsa.use-acp    = true
        api.acp.auto-profile = true
        api.acp.auto-port    = true
        session.suspend-timeout-seconds = 0
      }
    }
  }
]
WPCONF

cat > /etc/asound.conf <<'ASOUNDCONF'
pcm.!default {
    type pipewire
    playback_node -1
    capture_node  -1
}
ctl.!default {
    type pipewire
}
ASOUNDCONF

mkdir -p /etc/security/limits.d
cat > /etc/security/limits.d/95-pipewire.conf <<'RTLIM'
@audio   -  rtprio   95
@audio   -  memlock  unlimited
RTLIM

usermod -aG audio admin 2>/dev/null || true

mkdir -p /etc/systemd/system.conf.d
cat > /etc/systemd/system.conf.d/00-quiet.conf <<'QUIETCONF'
[Manager]
ShowStatus=no
LogLevel=crit
DefaultStandardOutput=journal
DefaultStandardError=journal
QUIETCONF

mkdir -p /etc/NetworkManager/conf.d
cat > /etc/NetworkManager/conf.d/dhcp-client.conf <<'NMCONF'
[main]
dhcp=dhclient
NMCONF

cat > /etc/NetworkManager/conf.d/10-ethernet.conf <<'NMETH'
[keyfile]
unmanaged-devices=none
NMETH

ln -sf /lib/systemd/system/udisks2.service \
    /etc/systemd/system/multi-user.target.wants/udisks2.service 2>/dev/null || true

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

mkdir -p /etc/plymouth
cat > /etc/plymouth/plymouthd.conf <<'PLYMCONF'
[Daemon]
Theme=raytolfas
ShowDelay=0
PLYMCONF

rm -rf /tmp/fluent-kde
git clone --depth=1 https://github.com/vinceliuice/Fluent-kde.git /tmp/fluent-kde
(cd /tmp/fluent-kde && ./install.sh -c dark --round)
mkdir -p /usr/share/sddm/themes/Fluent
cp -r /tmp/fluent-kde/sddm/Fluent-5.0/* /usr/share/sddm/themes/Fluent/
rm -rf /tmp/fluent-kde

rm -rf /opt/waydroid-extras
git clone --depth=1 https://github.com/casualsnek/waydroid_script.git /opt/waydroid-extras || true
pip3 install InquirerPy tqdm requests --break-system-packages 2>/dev/null || true

if ! id admin >/dev/null 2>&1; then
    useradd -m -s /bin/bash -G sudo,video,audio,input,render admin
    echo 'admin:admin' | chpasswd
    echo 'root:root' | chpasswd
    echo 'admin ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/admin
    chmod 0440 /etc/sudoers.d/admin
else
    usermod -a -G audio,video,input,render admin 2>/dev/null || true
fi

mkdir -p /etc/sddm.conf.d
cat << 'AUTOLOGIN' > /etc/sddm.conf.d/autologin.conf
[Autologin]
User=admin
Session=plasma
Relogin=false

[Theme]
Current=Fluent
CursorTheme=breeze_cursors
AUTOLOGIN

echo 'd1-pc' > /etc/hostname
cat << 'HOSTS' > /etc/hosts
127.0.0.1 localhost
127.0.1.1 d1-pc
HOSTS

cat << 'OSREL' > /etc/os-release
NAME="Raytolfas OS"
PRETTY_NAME="Raytolfas OS D1 (v26.10.0)"
ID=raytolfas
ID_LIKE="ubuntu debian"
VERSION="v26.10.0"
VERSION_ID="26.10.0"
VERSION_CODENAME="noble"
HOME_URL="https://raytolfas.com"
OSREL

cp -f /etc/os-release /usr/lib/os-release
echo 'Raytolfas OS D1 (v26.10.0) \n \l' > /etc/issue
echo 'Raytolfas OS D1 (v26.10.0)' > /etc/issue.net

apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
CHROOT_END

echo "[plasma-rootfs] Installing fastfetch from GitHub releases..."
sudo chroot "${BUILD_DIR}" /bin/bash << 'FASTFETCH_INSTALL'
curl -fsSL "https://github.com/fastfetch-cli/fastfetch/releases/download/2.28.0/fastfetch-linux-amd64.deb" \
    -o /tmp/fastfetch.deb && dpkg -i /tmp/fastfetch.deb && rm -f /tmp/fastfetch.deb || true
FASTFETCH_INSTALL

echo "[plasma-rootfs] Installing Raytolfas Plymouth boot splash theme..."

PLYMOUTH_THEME_DIR="${BUILD_DIR}/usr/share/plymouth/themes/raytolfas"
sudo mkdir -p "${PLYMOUTH_THEME_DIR}"

cat << 'PLYMSCRIPT' | sudo tee "${PLYMOUTH_THEME_DIR}/raytolfas.script" > /dev/null

Window.SetBackgroundTopColor(0.04, 0.055, 0.09);
Window.SetBackgroundBottomColor(0.02, 0.03, 0.06);

title_image = Image.Text("Raytolfas OS D1", 1.0, 1.0, 1.0, 1.0, "Sans Bold 18");
title_sprite = Sprite(title_image);
title_sprite.SetX(Window.GetWidth() / 2 - title_image.GetWidth() / 2);
title_sprite.SetY(Window.GetHeight() / 2 + 20);

bar_width = 240;
bar_height = 4;
bar_x = Window.GetWidth() / 2 - bar_width / 2;
bar_y = Window.GetHeight() / 2 + 70;

bar_bg_image = Image(bar_width, bar_height);
bar_bg = bar_bg_image.Scale(bar_width, bar_height);
bar_bg_sprite = Sprite(bar_bg);
bar_bg_sprite.SetX(bar_x);
bar_bg_sprite.SetY(bar_y);
bar_bg_sprite.SetOpacity(0.25);

progress_image = Image(bar_width, bar_height);
progress_sprite = Sprite();
progress_sprite.SetX(bar_x);
progress_sprite.SetY(bar_y);

fun refresh_callback() {
    local.time = Math.Mod(Plymouth.GetTime() * 0.7, 1.0);
    local.pw = bar_width * 0.35;
    local.px = bar_x + time * (bar_width + pw) - pw;
    local.visible_w = Math.Max(0, Math.Min(pw, bar_x + bar_width - px));
    if (visible_w > 0) {
        local.bar_img = Image(visible_w, bar_height);
        progress_sprite.SetImage(bar_img);
        progress_sprite.SetX(Math.Max(bar_x, px));
    }
}
Plymouth.SetRefreshFunction(refresh_callback);

fun boot_progress_callback(duration, progress) {}
Plymouth.SetBootProgressFunction(boot_progress_callback);
PLYMSCRIPT

cat << 'PLYMTHEME' | sudo tee "${PLYMOUTH_THEME_DIR}/raytolfas.plymouth" > /dev/null
[Plymouth Theme]
Name=Raytolfas
Description=Raytolfas OS D1 Boot Splash
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/raytolfas
ScriptFile=/usr/share/plymouth/themes/raytolfas/raytolfas.script
PLYMTHEME

sudo chroot "${BUILD_DIR}" /bin/bash << 'PLYM_REGISTER'
if command -v update-alternatives &>/dev/null; then
    update-alternatives --install /usr/share/plymouth/themes/default.plymouth \
        default.plymouth \
        /usr/share/plymouth/themes/raytolfas/raytolfas.plymouth 200 || true
    update-alternatives --set default.plymouth \
        /usr/share/plymouth/themes/raytolfas/raytolfas.plymouth 2>/dev/null || true
fi
if command -v update-initramfs &>/dev/null; then
    update-initramfs -u 2>/dev/null || true
fi
PLYM_REGISTER

echo "[plasma-rootfs] Installing Raytolfas official wallpaper..."

sudo rm -rf "${BUILD_DIR}/usr/share/wallpapers/Fluent"* 2>/dev/null || true
sudo rm -rf "${BUILD_DIR}/usr/share/wallpapers/Next"* 2>/dev/null || true
sudo mkdir -p "${BUILD_DIR}/usr/share/wallpapers/Raytolfas/contents/images"

if [ -f "${REPO_ROOT}/assets/basic-background.png" ]; then
    sudo cp -f "${REPO_ROOT}/assets/basic-background.png" "${BUILD_DIR}/usr/share/wallpapers/Raytolfas/contents/images/1920x1080.png"
    sudo cp -f "${REPO_ROOT}/assets/basic-background.png" "${BUILD_DIR}/usr/share/wallpapers/Raytolfas/wallpaper.png"
    sudo mkdir -p "${BUILD_DIR}/usr/share/sddm/themes/Fluent"
    sudo cp -f "${REPO_ROOT}/assets/basic-background.png" "${BUILD_DIR}/usr/share/sddm/themes/Fluent/background.png"

    cat << 'METADATA' | sudo tee "${BUILD_DIR}/usr/share/wallpapers/Raytolfas/metadata.desktop" > /dev/null
[Desktop Entry]
Name=Raytolfas
X-KDE-PluginInfo-Name=Raytolfas
X-KDE-PluginInfo-Author=Raytolfas OS Team
X-KDE-PluginInfo-Email=dev@raytolfas.com
X-KDE-PluginInfo-License=Proprietary
METADATA
fi

echo "[plasma-rootfs] Installing white Raytolfas logo across all icon directories..."

LOGO_WHITE_SVG="${REPO_ROOT}/assets/logo-white.svg"
LOGO_WHITE_PNG="${REPO_ROOT}/assets/logo-white.png"

if [ -f "${LOGO_WHITE_SVG}" ] && [ ! -f "${LOGO_WHITE_PNG}" ]; then
    rsvg-convert -w 512 -h 512 "${LOGO_WHITE_SVG}" -o "${LOGO_WHITE_PNG}"
fi

sudo mkdir -p "${BUILD_DIR}/usr/share/icons/hicolor/scalable/apps"
sudo mkdir -p "${BUILD_DIR}/usr/share/icons/hicolor/512x512/apps"
sudo mkdir -p "${BUILD_DIR}/usr/share/icons/hicolor/48x48/apps"
sudo mkdir -p "${BUILD_DIR}/usr/share/icons/breeze/apps/48"
sudo mkdir -p "${BUILD_DIR}/usr/share/icons/breeze-dark/apps/48"
sudo mkdir -p "${BUILD_DIR}/usr/share/icons/Papirus/48x48/places"
sudo mkdir -p "${BUILD_DIR}/usr/share/icons/Papirus-Dark/48x48/places"
sudo mkdir -p "${BUILD_DIR}/usr/share/icons/Papirus-Dark/48x48/apps"
sudo mkdir -p "${BUILD_DIR}/usr/share/pixmaps"

for dest in \
    "${BUILD_DIR}/usr/share/icons/hicolor/scalable/apps/start-here-raytolfas.svg" \
    "${BUILD_DIR}/usr/share/icons/hicolor/scalable/apps/raytolfas-logo.svg" \
    "${BUILD_DIR}/usr/share/icons/hicolor/scalable/apps/start-here.svg" \
    "${BUILD_DIR}/usr/share/icons/hicolor/scalable/apps/start-here-kde.svg" \
    "${BUILD_DIR}/usr/share/icons/hicolor/scalable/apps/distributor-logo.svg" \
    "${BUILD_DIR}/usr/share/icons/hicolor/scalable/apps/distributor-logo-raytolfas.svg" \
    "${BUILD_DIR}/usr/share/icons/breeze/apps/48/start-here-kde.svg" \
    "${BUILD_DIR}/usr/share/icons/breeze-dark/apps/48/start-here-kde.svg" \
    "${BUILD_DIR}/usr/share/icons/breeze-dark/apps/48/start-here.svg" \
    "${BUILD_DIR}/usr/share/icons/Papirus-Dark/48x48/places/start-here-kde.svg" \
    "${BUILD_DIR}/usr/share/icons/Papirus-Dark/48x48/places/start-here.svg" \
    "${BUILD_DIR}/usr/share/icons/Papirus-Dark/48x48/places/distributor-logo.svg" \
    "${BUILD_DIR}/usr/share/icons/Papirus-Dark/48x48/places/distributor-logo-raytolfas.svg" \
    "${BUILD_DIR}/usr/share/icons/Papirus-Dark/48x48/apps/raytolfas-logo.svg" \
    "${BUILD_DIR}/usr/share/icons/Papirus-Dark/48x48/apps/start-here-raytolfas.svg" \
    "${BUILD_DIR}/usr/share/pixmaps/raytolfas-logo.svg" \
    "${BUILD_DIR}/usr/share/pixmaps/start-here-raytolfas.svg"; do
    sudo cp -f "${LOGO_WHITE_SVG}" "${dest}"
done

if [ -f "${LOGO_WHITE_PNG}" ]; then
    sudo cp -f "${LOGO_WHITE_PNG}" "${BUILD_DIR}/usr/share/pixmaps/raytolfas-logo.png"
    sudo cp -f "${LOGO_WHITE_PNG}" "${BUILD_DIR}/usr/share/icons/hicolor/512x512/apps/start-here-raytolfas.png"
    sudo cp -f "${LOGO_WHITE_PNG}" "${BUILD_DIR}/usr/share/icons/hicolor/512x512/apps/raytolfas-logo.png"
fi

echo "[plasma-rootfs] Creating official Raytolfas Look-and-Feel package..."

LOOKANDFEEL_DIR="${BUILD_DIR}/usr/share/plasma/look-and-feel/org.raytolfas.desktop"
sudo mkdir -p "${LOOKANDFEEL_DIR}/contents/splash/images"
sudo mkdir -p "${LOOKANDFEEL_DIR}/contents/layouts"

cat << 'METADATAJSON' | sudo tee "${LOOKANDFEEL_DIR}/metadata.json" > /dev/null
{
    "KPlugin": {
        "Authors": [
            {
                "Email": "dev@raytolfas.com",
                "Name": "Raytolfas OS Team"
            }
        ],
        "Description": "Official Raytolfas OS Dark Theme",
        "Id": "org.raytolfas.desktop",
        "Name": "System Dark",
        "ServiceTypes": [
            "Plasma/LookAndFeel"
        ],
        "Version": "1.0",
        "Website": "https://raytolfas.com"
    }
}
METADATAJSON

cat << 'METADATADESK' | sudo tee "${LOOKANDFEEL_DIR}/metadata.desktop" > /dev/null
[Desktop Entry]
Comment=Official Raytolfas OS Dark Theme
Encoding=UTF-8
Keywords=
Name=System Dark
Name[ru]=System Dark
Type=Service
X-KDE-PluginInfo-Author=Raytolfas OS Team
X-KDE-PluginInfo-Email=dev@raytolfas.com
X-KDE-PluginInfo-License=Proprietary
X-KDE-PluginInfo-Name=org.raytolfas.desktop
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-Website=https://raytolfas.com
X-KDE-ServiceTypes=Plasma/LookAndFeel
METADATADESK

LOOKANDFEEL_LIGHT="${BUILD_DIR}/usr/share/plasma/look-and-feel/org.raytolfas.light"
sudo mkdir -p "${LOOKANDFEEL_LIGHT}/contents"

cat << 'METADATALIGHT' | sudo tee "${LOOKANDFEEL_LIGHT}/metadata.desktop" > /dev/null
[Desktop Entry]
Comment=Official Raytolfas OS Light Theme
Encoding=UTF-8
Keywords=
Name=System
Name[ru]=System
Type=Service
X-KDE-PluginInfo-Author=Raytolfas OS Team
X-KDE-PluginInfo-Email=dev@raytolfas.com
X-KDE-PluginInfo-License=Proprietary
X-KDE-PluginInfo-Name=org.raytolfas.light
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-Website=https://raytolfas.com
X-KDE-ServiceTypes=Plasma/LookAndFeel
METADATALIGHT

cat << 'DEFAULTSLIGHT' | sudo tee "${LOOKANDFEEL_LIGHT}/contents/defaults" > /dev/null
[kcminputrc][Mouse]
cursorTheme=breeze_cursors

[kdeglobals][General]
ColorScheme=FluentLight

[kdeglobals][Icons]
Theme=Papirus-Dark

[kdeglobals][KDE]
LookAndFeelPackage=org.raytolfas.light
widgetStyle=Breeze
AnimationDurationFactor=0.85

[kwinrc][org.kde.kdecoration2]
ButtonsOnLeft=
ButtonsOnRight=IAX
library=org.kde.kwin.aurorae
theme=__aurorae__svg__Fluent-round-dark
Animations=true

[plasmarc][Theme]
name=Fluent-round-dark
DEFAULTSLIGHT

cat << 'DEFAULTS' | sudo tee "${LOOKANDFEEL_DIR}/contents/defaults" > /dev/null
[kcminputrc][Mouse]
cursorTheme=breeze_cursors

[kdeglobals][General]
ColorScheme=FluentDark

[kdeglobals][Icons]
Theme=Papirus-Dark

[kdeglobals][KDE]
LookAndFeelPackage=org.raytolfas.desktop
widgetStyle=Breeze
AnimationDurationFactor=0.85

[kwinrc][org.kde.kdecoration2]
ButtonsOnLeft=
ButtonsOnRight=IAX
library=org.kde.kwin.aurorae
theme=__aurorae__svg__Fluent-round-dark

[plasmarc][Theme]
name=Fluent-round-dark
DEFAULTS

cat << 'SPLASHQML' | sudo tee "${LOOKANDFEEL_DIR}/contents/splash/Splash.qml" > /dev/null
import QtQuick 2.15

Rectangle {
    id: root
    anchors.fill: parent
    color: "#0a0e17"

    property int stage: 0

    Column {
        anchors.centerIn: parent
        spacing: 28

        Image {
            id: logo
            width: 120
            height: 120
            source: "images/logo-white.png"
            sourceSize.width: 120
            sourceSize.height: 120
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            smooth: true
            opacity: 0.0

            Behavior on opacity {
                NumberAnimation { duration: 600; easing.type: Easing.InOutSine }
            }

            SequentialAnimation on opacity {
                running: true
                loops: Animation.Infinite
                NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.75; duration: 800; easing.type: Easing.InOutSine }
            }
        }

        Text {
            text: "Raytolfas OS D1"
            color: "#ffffff"
            font.pixelSize: 24
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Rectangle {
            width: 200
            height: 3
            radius: 2
            color: "#1e293b"
            clip: true
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                width: 60
                height: 3
                radius: 2
                color: "#0078D4"

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: true
                    PropertyAnimation { from: -60; to: 200; duration: 1400; easing.type: Easing.InOutQuad }
                }
            }
        }
    }
}
SPLASHQML

sudo cp -f "${LOGO_WHITE_SVG}" "${LOOKANDFEEL_DIR}/contents/splash/images/logo-white.svg"
sudo cp -f "${LOGO_WHITE_PNG}" "${LOOKANDFEEL_DIR}/contents/splash/images/logo-white.png"

for theme_dir in \
    "${LOOKANDFEEL_LIGHT}" \
    "${BUILD_DIR}/usr/share/plasma/look-and-feel/com.github.vinceliuice.Fluent-round-dark" \
    "${LOOKANDFEEL_DIR}"; do
    if [ -d "${theme_dir}" ]; then
        sudo mkdir -p "${theme_dir}/contents/splash/images"
        sudo cp -f "${LOOKANDFEEL_DIR}/contents/splash/Splash.qml" "${theme_dir}/contents/splash/Splash.qml"
        sudo cp -f "${LOGO_WHITE_SVG}" "${theme_dir}/contents/splash/images/logo-white.svg"
        sudo cp -f "${LOGO_WHITE_PNG}" "${theme_dir}/contents/splash/images/logo-white.png"
        for comp in logout lockscreen systemdialog components; do
            if [ -d "${BUILD_DIR}/usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents/${comp}" ] && [ ! -d "${theme_dir}/contents/${comp}" ]; then
                sudo cp -r "${BUILD_DIR}/usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents/${comp}" "${theme_dir}/contents/"
            fi
        done
    fi
done

echo "[plasma-rootfs] Configuring native floating bottom panel layout script..."

cat << 'LAYOUTJS' | sudo tee "${LOOKANDFEEL_DIR}/contents/layouts/org.kde.plasma.desktop-layout.js" > /dev/null
var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = 'org.kde.image';
    desktopsArray[j].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktopsArray[j].writeConfig("Image", "/usr/share/wallpapers/Raytolfas/wallpaper.png");
    desktopsArray[j].writeConfig("FillMode", 2);
}

var panel = new Panel;
var panelScreen = panel.screen;

panel.location = "bottom";
panel.height = 46;
panel.floating = false;

var kickoff = panel.addWidget("org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["General"];
kickoff.writeConfig("icon", "start-here-raytolfas");
kickoff.writeConfig("useCustomButtonImage", true);
kickoff.writeConfig("customButtonImage", "/usr/share/icons/hicolor/scalable/apps/start-here-raytolfas.svg");

kickoff.currentConfigGroup = ["Shortcuts"];
kickoff.writeConfig("global", "Alt+F1");

panel.addWidget("org.kde.plasma.pager");

var icontasks = panel.addWidget("org.kde.plasma.icontasks");
icontasks.currentConfigGroup = ["General"];
icontasks.writeConfig("launchers", [
    "applications:org.kde.dolphin.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:org.kde.plasma-systemmonitor.desktop",
    "applications:systemsettings.desktop",
    "applications:raytolfas-android.desktop"
]);
icontasks.writeConfig("indicateAudioStreams", true);
icontasks.writeConfig("maxRows", 1);
icontasks.writeConfig("fill", true);

panel.addWidget("org.kde.plasma.marginsseparator");
panel.addWidget("org.kde.plasma.systemtray");

var panelClock = panel.addWidget("org.kde.plasma.digitalclock");
panelClock.currentConfigGroup = ["Appearance"];
panelClock.writeConfig("use24hFormat", 2);
panelClock.writeConfig("showSeconds", 0);
panelClock.writeConfig("showDate", false);

panel.addWidget("org.kde.plasma.showdesktop");
LAYOUTJS

if [ -d "${BUILD_DIR}/usr/share/plasma/look-and-feel/com.github.vinceliuice.Fluent-round-dark/contents/layouts" ]; then
    sudo cp -f "${LOOKANDFEEL_DIR}/contents/layouts/org.kde.plasma.desktop-layout.js" "${BUILD_DIR}/usr/share/plasma/look-and-feel/com.github.vinceliuice.Fluent-round-dark/contents/layouts/org.kde.plasma.desktop-layout.js"
fi

sudo mkdir -p "${BUILD_DIR}/usr/share/plasma/shells/org.kde.plasma.desktop/contents"
sudo mkdir -p "${BUILD_DIR}/usr/share/plasma/layout-templates/org.kde.plasma.desktop.defaultPanel/contents"
sudo cp -f "${LOOKANDFEEL_DIR}/contents/layouts/org.kde.plasma.desktop-layout.js" "${BUILD_DIR}/usr/share/plasma/shells/org.kde.plasma.desktop/contents/layout.js"
sudo cp -f "${LOOKANDFEEL_DIR}/contents/layouts/org.kde.plasma.desktop-layout.js" "${BUILD_DIR}/usr/share/plasma/layout-templates/org.kde.plasma.desktop.defaultPanel/contents/layout.js"

echo "[plasma-rootfs] Configuring Calamares GUI installer..."

CALAMARES_BRANDING_DIR="${BUILD_DIR}/etc/calamares/branding/raytolfas"
sudo mkdir -p "${CALAMARES_BRANDING_DIR}"
sudo mkdir -p "${BUILD_DIR}/etc/calamares/modules"

cat << 'CALSETTINGS' | sudo tee "${BUILD_DIR}/etc/calamares/settings.conf" > /dev/null
modules-search: [ local, /usr/lib/x86_64-linux-gnu/calamares/modules, /usr/share/calamares/modules ]

instances:
- id:       rootfs
  module:   unpackfs
  config:   unpackfs.conf

sequence:
- show:
  - welcome
  - locale
  - keyboard
  - partition
  - users
  - summary
- exec:
  - partition
  - mount
  - unpackfs@rootfs
  - machineid
  - fstab
  - locale
  - keyboard
  - localecfg
  - users
  - displaymanager
  - networkcfg
  - packages
  - grubcfg
  - bootloader
  - umount
- show:
  - finished

branding: raytolfas

prompt-install: true
dont-chroot: false
oem-setup: false
disable-cancel: false
expert-mode: false
CALSETTINGS

cat << 'CALBRAND' | sudo tee "${CALAMARES_BRANDING_DIR}/branding.desc" > /dev/null
---
componentName:  raytolfas
welcomeStyleCalamares: true
welcomeExpandingLogo: true
windowExpanding: normal
windowSize: 840px,560px
windowPlacement: center

strings:
    productName:         "Raytolfas OS"
    shortProductName:    "Raytolfas"
    version:             "v26.10.0"
    shortVersion:        "D1"
    versionedName:       "Raytolfas OS D1"
    shortVersionedName:  "Raytolfas D1"
    bootloaderEntryName: "Raytolfas OS"
    productUrl:          "https://raytolfas.com"
    supportUrl:          "https://raytolfas.com"
    knownIssuesUrl:      "https://raytolfas.com"
    releaseNotesUrl:     "https://raytolfas.com"

images:
    productLogo:         "logo-white.png"
    productIcon:         "logo-white.png"
    productWelcome:      "welcome.png"

slideshow:               "show.qml"

style:
   SidebarBackground:        "#0e131f"
   SidebarText:              "#a0aec0"
   SidebarTextCurrent:       "#ffffff"
   SidebarBackgroundCurrent: "#0078D4"
CALBRAND

sudo cp -f "${REPO_ROOT}/assets/branding/calamares/stylesheet.qss" "${CALAMARES_BRANDING_DIR}/stylesheet.qss"

cat << 'WELCOMECONF' | sudo tee "${BUILD_DIR}/etc/calamares/modules/welcome.conf" > /dev/null
---
showSupportUrl: false
showKnownIssuesUrl: false
showReleaseNotesUrl: false
showDonateUrl: false
WELCOMECONF

cat << 'UNPACKCONF' | sudo tee "${BUILD_DIR}/etc/calamares/modules/unpackfs.conf" > /dev/null
---
unpack:
    -   source: "/rofs"
        sourcefs: "file"
        destination: ""
UNPACKCONF

sudo mkdir -p "${BUILD_DIR}/rofs" "${BUILD_DIR}/cdrom"

if [ -f "${LOGO_WHITE_PNG}" ]; then
    sudo cp -f "${LOGO_WHITE_PNG}" "${CALAMARES_BRANDING_DIR}/logo-white.png"
fi

if [ -f "${REPO_ROOT}/assets/basic-background.png" ]; then
    sudo cp -f "${REPO_ROOT}/assets/basic-background.png" "${CALAMARES_BRANDING_DIR}/welcome.png"
fi

cat << 'SHOWQML' | sudo tee "${CALAMARES_BRANDING_DIR}/show.qml" > /dev/null
import QtQuick 2.0
import QtQuick.Controls 2.0

Rectangle {
    color: "#0a0e17"
    Text {
        anchors.centerIn: parent
        text: "Installing Raytolfas OS..."
        color: "#ffffff"
        font.pixelSize: 18
    }
}
SHOWQML

cat << 'CALWRAP' | sudo tee "${BUILD_DIR}/usr/local/bin/raytolfas-install" > /dev/null
xhost +si:localuser:root 2>/dev/null || xhost + 2>/dev/null || true
export DISPLAY="${DISPLAY:-:0}"
export QT_QPA_PLATFORM="xcb"
export QT_AUTO_SCREEN_SCALE_FACTOR=1
exec sudo -E /usr/bin/calamares -d "$@"
CALWRAP
sudo chmod 0755 "${BUILD_DIR}/usr/local/bin/raytolfas-install"

cat << 'CALDESK' | sudo tee "${BUILD_DIR}/usr/share/applications/calamares.desktop" > /dev/null
[Desktop Entry]
Type=Application
Version=1.0
Name=Install Raytolfas OS
GenericName=Live System Installer
Comment=Install Raytolfas OS to Hard Drive or SSD
Exec=/usr/local/bin/raytolfas-install
Icon=start-here-raytolfas
Terminal=false
Categories=Qt;System;
StartupNotify=true
CALDESK

sudo mkdir -p "${BUILD_DIR}/etc/calamares/modules"
if [ -d "${REPO_ROOT}/config/calamares" ]; then
    for f in "${REPO_ROOT}/config/calamares"/*.conf; do
        if [ -f "$f" ]; then
            fname=$(basename "$f")
            if [ "$fname" = "settings.conf" ]; then
                sudo cp -f "$f" "${BUILD_DIR}/etc/calamares/settings.conf"
            else
                sudo cp -f "$f" "${BUILD_DIR}/etc/calamares/modules/$fname"
            fi
        fi
    done
fi

sudo mkdir -p "${BUILD_DIR}/etc/polkit-1/rules.d"
sudo rm -f "${BUILD_DIR}/etc/polkit-1/rules.d/"*
if [ -f "${REPO_ROOT}/config/polkit/40-raytolfas.rules" ]; then
    sudo cp -f "${REPO_ROOT}/config/polkit/40-raytolfas.rules" "${BUILD_DIR}/etc/polkit-1/rules.d/40-raytolfas.rules"
fi
sudo chown -R root:polkitd "${BUILD_DIR}/etc/polkit-1/rules.d"
sudo chmod 755 "${BUILD_DIR}/etc/polkit-1/rules.d"
sudo chmod 644 "${BUILD_DIR}/etc/polkit-1/rules.d/"* 2>/dev/null || true

if [ -f "${REPO_ROOT}/config/systemd/logind.conf.d/40-power.conf" ]; then
    sudo mkdir -p "${BUILD_DIR}/etc/systemd/logind.conf.d"
    sudo cp -f "${REPO_ROOT}/config/systemd/logind.conf.d/40-power.conf" "${BUILD_DIR}/etc/systemd/logind.conf.d/40-power.conf"
fi

if [ -d "${REPO_ROOT}/apps/welcome" ]; then
    sudo mkdir -p "${BUILD_DIR}/usr/share/raytolfas/welcome"
    sudo cp -rf "${REPO_ROOT}/apps/welcome/"* "${BUILD_DIR}/usr/share/raytolfas/welcome/"
    cat << 'WELCOMERUN' | sudo tee "${BUILD_DIR}/usr/local/bin/raytolfas-welcome" > /dev/null
if [ -f "${HOME}/.config/raytolfas/welcome_done" ] && [ "$1" != "--force" ]; then
    exit 0
fi
sleep 1.2
exec python3 /usr/share/raytolfas/welcome/main.py "$@"
WELCOMERUN
    sudo chmod 0755 "${BUILD_DIR}/usr/local/bin/raytolfas-welcome"

    sudo mkdir -p "${BUILD_DIR}/etc/skel/.config/autostart"
    cat << 'WELCOMEDESK' | sudo tee "${BUILD_DIR}/etc/skel/.config/autostart/raytolfas-welcome.desktop" > /dev/null
[Desktop Entry]
Type=Application
Name=Raytolfas OS Welcome
Exec=/usr/local/bin/raytolfas-welcome
X-KDE-autostart-phase=2
X-KDE-autostart-after=panel
OnlyShowIn=KDE;
Hidden=false
NoDisplay=true
WELCOMEDESK

    cat << 'WELCOMEMENU' | sudo tee "${BUILD_DIR}/usr/share/applications/raytolfas-welcome.desktop" > /dev/null
[Desktop Entry]
Type=Application
Name=Welcome
Comment=Welcome to Raytolfas OS
Exec=raytolfas-welcome --force
Icon=raytolfas-logo
Categories=System;Qt;
Terminal=false
WELCOMEMENU
fi

if [ -d "${REPO_ROOT}/apps/control-center" ]; then
    sudo mkdir -p "${BUILD_DIR}/usr/share/raytolfas/control-center"
    sudo cp -rf "${REPO_ROOT}/apps/control-center/"* "${BUILD_DIR}/usr/share/raytolfas/control-center/"
    cat << 'CCRUN' | sudo tee "${BUILD_DIR}/usr/local/bin/raytolfas-control-center" > /dev/null
exec python3 /usr/share/raytolfas/control-center/main.py "$@"
CCRUN
    sudo chmod 0755 "${BUILD_DIR}/usr/local/bin/raytolfas-control-center"

    cat << 'CCDESK' | sudo tee "${BUILD_DIR}/usr/share/applications/raytolfas-control-center.desktop" > /dev/null
[Desktop Entry]
Type=Application
Name=Raytolfas Control Center
Comment=System Information, Updates, and Settings
Exec=raytolfas-control-center
Icon=raytolfas-logo
Categories=Settings;System;Qt;
Terminal=false
StartupNotify=true
CCDESK
fi

echo "[plasma-rootfs] Downloading Proton-GE (x86_64)..."
sudo chroot "${BUILD_DIR}" /bin/bash << 'PROTON_GE_INSTALL'
DOWNLOAD_URL=$(curl -fsSL "https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest" \
    | grep '"browser_download_url"' | grep -i 'x86_64\.tar\.gz"' | head -1 | cut -d'"' -f4 2>/dev/null)

if [ -z "${DOWNLOAD_URL}" ]; then
    DOWNLOAD_URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton11-7/GE-Proton11-7-x86_64.tar.gz"
fi

PROTON_VER=$(basename "${DOWNLOAD_URL}" .tar.gz)
echo "[proton-ge] Downloading & Installing ${PROTON_VER}..."

mkdir -p /opt/GE-Proton
if curl -fsSL -L --connect-timeout 60 "${DOWNLOAD_URL}" -o /tmp/proton-ge.tar.gz; then
    tar -xzf /tmp/proton-ge.tar.gz -C /opt/GE-Proton --strip-components=1
    rm -f /tmp/proton-ge.tar.gz
    echo "[proton-ge] Installed ${PROTON_VER} to /opt/GE-Proton successfully!"
else
    echo "[proton-ge] Download failed — Wine will be used as fallback"
fi
PROTON_GE_INSTALL

sudo cp -f "${REPO_ROOT}/scripts/tools/raytolfas-proton" "${BUILD_DIR}/usr/local/bin/raytolfas-proton"
sudo chmod 0755 "${BUILD_DIR}/usr/local/bin/raytolfas-proton"

cat << 'WINEDESK' | sudo tee "${BUILD_DIR}/usr/share/applications/raytolfas-wine.desktop" > /dev/null
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

sudo mkdir -p "${BUILD_DIR}/etc/binfmt.d"
cat << 'WINEBINFMT' | sudo tee "${BUILD_DIR}/etc/binfmt.d/wine.conf" > /dev/null
:DOSWin:M::MZ::/usr/local/bin/raytolfas-proton:
WINEBINFMT

sudo cp -f "${REPO_ROOT}/scripts/tools/raytolfas-android" "${BUILD_DIR}/usr/local/bin/raytolfas-android"
sudo chmod 0755 "${BUILD_DIR}/usr/local/bin/raytolfas-android"

cat << 'WAYDROIDDESK' | sudo tee "${BUILD_DIR}/usr/share/applications/raytolfas-android.desktop" > /dev/null
[Desktop Entry]
Type=Application
Name=Android Subsystem (Waydroid)
Comment=Launch Android apps on Wayland
Exec=raytolfas-android
Icon=android-studio
Terminal=false
Categories=System;Emulator;
WAYDROIDDESK

sudo cp -f "${REPO_ROOT}/scripts/tools/raytolfas-apk-install" "${BUILD_DIR}/usr/local/bin/raytolfas-apk-install"
sudo chmod 0755 "${BUILD_DIR}/usr/local/bin/raytolfas-apk-install"

cat << 'APKDESK' | sudo tee "${BUILD_DIR}/usr/share/applications/raytolfas-apk.desktop" > /dev/null
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

sudo mkdir -p "${BUILD_DIR}/etc/xdg"
cat << 'MIMEAPPS' | sudo tee "${BUILD_DIR}/etc/xdg/mimeapps.list" > /dev/null
[Default Applications]
application/x-ms-dos-executable=raytolfas-wine.desktop
application/x-msdownload=raytolfas-wine.desktop
application/x-dosexec=raytolfas-wine.desktop
application/vnd.microsoft.portable-executable=raytolfas-wine.desktop
application/vnd.android.package-archive=raytolfas-apk.desktop
MIMEAPPS

cat << 'ZRAMSVC' | sudo tee "${BUILD_DIR}/etc/systemd/system/raytolfas-zram.service" > /dev/null
[Unit]
Description=Raytolfas OS ZRAM Swap Auto-Allocator
After=local-fs.target
DefaultDependencies=no

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'modprobe zram 2>/dev/null || true; [ -b /dev/zram0 ] || true; echo zstd > /sys/block/zram0/comp_algorithm 2>/dev/null || true; RAM_KB=$$(grep MemTotal /proc/meminfo | awk "{print \$$2}"); ZRAM_KB=$$(( RAM_KB / 2 )); echo $${ZRAM_KB}K > /sys/block/zram0/disksize 2>/dev/null || true; mkswap /dev/zram0 >/dev/null 2>&1 || true; swapon -p 100 /dev/zram0 >/dev/null 2>&1 || true'
RemainAfterExit=yes

[Install]
WantedBy=basic.target
ZRAMSVC
sudo chroot "${BUILD_DIR}" systemctl enable raytolfas-zram.service 2>/dev/null || true
sudo chroot "${BUILD_DIR}" systemctl disable waydroid-container.service 2>/dev/null || true

echo "[plasma-rootfs] Configuring Global XDG Defaults..."

sudo mkdir -p "${BUILD_DIR}/etc/xdg"

cat << 'XDGKDEG' | sudo tee "${BUILD_DIR}/etc/xdg/kdeglobals" > /dev/null
[General]
ColorScheme=FluentDark
Name=Fluent Dark

[Icons]
Theme=Papirus-Dark

[KDE]
LookAndFeelPackage=org.raytolfas.desktop
SingleClick=false
ShowDeleteCommand=true
AnimationDurationFactor=0.85

[KDE-Global-Accelerators]
AnimationDurationFactor=0.85
XDGKDEG

cat << 'XDGKWIN' | sudo tee "${BUILD_DIR}/etc/xdg/kwinrc" > /dev/null
[Effect-blur]
BlurStrength=14
NoiseStrength=2

[Effect-slide]
Horizontal=false

[Effect-slidingpopups]
AnimationDuration=220

[Effect-scale]
Duration=200

[Plugins]
blurEnabled=true
contrastEnabled=true
translucencyEnabled=true
slideEnabled=true
slidingpopupsEnabled=true
scaleEnabled=true
fadeEnabled=true
kwin4_effect_translucencyEnabled=true
kwin4_effect_scaleinEnabled=true
kwin4_effect_fadedesktopEnabled=true

[org.kde.kdecoration2]
ButtonsOnLeft=
ButtonsOnRight=IAX
library=org.kde.kwin.aurorae
theme=__aurorae__svg__Fluent-round-dark
Animations=true
XDGKWIN

cat << 'XDGPLASM' | sudo tee "${BUILD_DIR}/etc/xdg/plasmarc" > /dev/null
[Theme]
name=Fluent-round-dark
XDGPLASM

cat << 'XDGKSPLASH' | sudo tee "${BUILD_DIR}/etc/xdg/ksplashrc" > /dev/null
[KSplash]
Engine=KSplashQML
Theme=org.raytolfas.desktop
XDGKSPLASH

cat << 'XDGKXKB' | sudo tee "${BUILD_DIR}/etc/xdg/kxkbrc" > /dev/null
[Layout]
DisplayNames=,
LayoutList=us,ru,ua
LayoutLoopCount=-1
Model=pc105
Options=grp:alt_shift_toggle,grp_led:scroll
ResetOldOptions=true
ShowFlag=true
ShowLabel=true
ShowLayoutIndicator=true
ShowSingle=false
SwitchMode=Global
Use=true
VariantList=,,
XDGKXKB

sudo mkdir -p "${BUILD_DIR}/etc/skel/.config"
sudo mkdir -p "${BUILD_DIR}/etc/skel/Desktop"
sudo mkdir -p "${BUILD_DIR}/home/admin/.config"
sudo mkdir -p "${BUILD_DIR}/home/admin/Desktop"

sudo cp -f "${BUILD_DIR}/etc/xdg/kdeglobals" "${BUILD_DIR}/etc/skel/.config/kdeglobals"
sudo cp -f "${BUILD_DIR}/etc/xdg/kwinrc" "${BUILD_DIR}/etc/skel/.config/kwinrc"
sudo cp -f "${BUILD_DIR}/etc/xdg/plasmarc" "${BUILD_DIR}/etc/skel/.config/plasmarc"
sudo cp -f "${BUILD_DIR}/etc/xdg/ksplashrc" "${BUILD_DIR}/etc/skel/.config/ksplashrc"
sudo cp -f "${BUILD_DIR}/etc/xdg/kxkbrc" "${BUILD_DIR}/etc/skel/.config/kxkbrc"

cat << 'LOCALERC' | sudo tee "${BUILD_DIR}/etc/skel/.config/plasma-localerc" > /dev/null
[Formats]
LANG=en_US.UTF-8
LC_TIME=ru_RU.UTF-8
use24HourClock=true

[Translations]
LANGUAGE=en_US:ru_RU:uk_UA
LOCALERC

sudo mkdir -p "${BUILD_DIR}/etc/xdg"
sudo cp -f "${BUILD_DIR}/etc/skel/.config/plasma-localerc" "${BUILD_DIR}/etc/xdg/plasma-localerc"

cat << 'INPUTRC' | sudo tee "${BUILD_DIR}/etc/skel/.config/kcminputrc" > /dev/null
[Mouse]
cursorTheme=breeze_cursors

[Touchpad]
tapToClick=true
naturalScroll=false
twoFingerTap=2
INPUTRC
sudo cp -f "${BUILD_DIR}/etc/skel/.config/kcminputrc" "${BUILD_DIR}/etc/xdg/kcminputrc"

cat << 'WALLETRC' | sudo tee "${BUILD_DIR}/etc/skel/.config/kwalletrc" > /dev/null
[Wallet]
Enabled=false
First Use=false
WALLETRC
sudo cp -f "${BUILD_DIR}/etc/skel/.config/kwalletrc" "${BUILD_DIR}/etc/xdg/kwalletrc"

cat << 'POWERDEVILRC' | sudo tee "${BUILD_DIR}/etc/skel/.config/powerdevilrc" > /dev/null
[BrightnessControl]
minimumBrightness=5

[Display]
turnOffDisplayWhenIdle=false

[LockScreen]
idleTimeout=0
POWERDEVILRC
sudo cp -f "${BUILD_DIR}/etc/skel/.config/powerdevilrc" "${BUILD_DIR}/etc/xdg/powerdevilrc"

cat << 'SCREENLOCKERRC' | sudo tee "${BUILD_DIR}/etc/skel/.config/kscreenlockerrc" > /dev/null
[Daemon]
Autolock=false
LockOnResume=false
Timeout=0
SCREENLOCKERRC
sudo cp -f "${BUILD_DIR}/etc/skel/.config/kscreenlockerrc" "${BUILD_DIR}/etc/xdg/kscreenlockerrc"

cat << 'KSMSERVERRC' | sudo tee "${BUILD_DIR}/etc/skel/.config/ksmserverrc" > /dev/null
[General]
confirmLogout=false
loginMode=default
shutdownType=2
KSMSERVERRC
sudo cp -f "${BUILD_DIR}/etc/skel/.config/ksmserverrc" "${BUILD_DIR}/etc/xdg/ksmserverrc"

cat << 'POWERRC' | sudo tee "${BUILD_DIR}/etc/skel/.config/powermanagementprofilesrc" > /dev/null
[AC][HandleButtonEvents]
powerButtonAction=1

[Battery][HandleButtonEvents]
powerButtonAction=1

[LowBattery][HandleButtonEvents]
powerButtonAction=1
POWERRC
sudo cp -f "${BUILD_DIR}/etc/skel/.config/powermanagementprofilesrc" "${BUILD_DIR}/etc/xdg/powermanagementprofilesrc"

sudo mkdir -p "${BUILD_DIR}/etc/udev/rules.d"
cat << 'UDEVBL' | sudo tee "${BUILD_DIR}/etc/udev/rules.d/99-backlight-min.rules" > /dev/null
SUBSYSTEM=="backlight", ACTION=="change", RUN+="/bin/sh -c 'M=$$(cat /sys/class/backlight/%k/max_brightness 2>/dev/null || echo 0); B=$$(cat /sys/class/backlight/%k/brightness 2>/dev/null || echo 0); MIN=$$(( M * 5 / 100 )); [ $$MIN -gt 0 ] && [ $$B -lt $$MIN ] && echo $$MIN > /sys/class/backlight/%k/brightness || true'"
UDEVBL

if [ -f "${REPO_ROOT}/assets/sound.ogg" ]; then
    echo "[plasma-rootfs] Installing login sound..."
    sudo mkdir -p "${BUILD_DIR}/usr/share/sounds/raytolfas"
    sudo cp -f "${REPO_ROOT}/assets/sound.ogg" "${BUILD_DIR}/usr/share/sounds/raytolfas/login.ogg"

    cat << 'SNDSCRIPT' | sudo tee "${BUILD_DIR}/usr/local/bin/raytolfas-login-sound" > /dev/null
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
    sudo chmod 0755 "${BUILD_DIR}/usr/local/bin/raytolfas-login-sound"

    sudo mkdir -p "${BUILD_DIR}/etc/skel/.config/autostart"
    cat << 'LOGINSND' | sudo tee "${BUILD_DIR}/etc/skel/.config/autostart/raytolfas-login-sound.desktop" > /dev/null
[Desktop Entry]
Type=Application
Name=Raytolfas Login Sound
Exec=/usr/local/bin/raytolfas-login-sound
X-KDE-autostart-phase=2
X-KDE-autostart-after=panel
OnlyShowIn=KDE;
Hidden=false
NoDisplay=true
LOGINSND
fi

echo "[plasma-rootfs] Configuring fastfetch terminal branding..."

sudo mkdir -p "${BUILD_DIR}/usr/share/fastfetch"
sudo mkdir -p "${BUILD_DIR}/etc/skel/.config/fastfetch"
sudo cp -f "${REPO_ROOT}/assets/b-logo.txt" "${BUILD_DIR}/usr/share/fastfetch/raytolfas-logo.txt"
sudo cp -f "${REPO_ROOT}/assets/m-logo.txt" "${BUILD_DIR}/usr/share/fastfetch/raytolfas-logo-small.txt"

cat << 'FFCONF' | sudo tee "${BUILD_DIR}/etc/skel/.config/fastfetch/config.jsonc" > /dev/null
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "type": "file",
        "source": "/usr/share/fastfetch/raytolfas-logo.txt",
        "color": { "1": "cyan" },
        "padding": { "top": 1, "left": 2 }
    },
    "display": {
        "separator": "  ",
        "color": { "keys": "blue", "title": "cyan", "output": "white" }
    },
    "modules": [
        { "type": "title",    "key": "" },
        "separator",
        { "type": "os",      "key": " OS    " },
        { "type": "kernel",  "key": " Kernel" },
        { "type": "de",      "key": " DE    " },
        { "type": "wm",      "key": " WM    " },
        { "type": "cpu",     "key": " CPU   " },
        { "type": "gpu",     "key": " GPU   " },
        { "type": "memory",  "key": " RAM   " },
        { "type": "disk",    "key": " Disk  " },
        { "type": "uptime",  "key": " Uptime" },
        "separator",
        "colors"
    ]
}
FFCONF

cat << 'BASHPRO' | sudo tee "${BUILD_DIR}/etc/profile.d/raytolfas-motd.sh" > /dev/null
if command -v fastfetch &>/dev/null && [ -t 1 ]; then
    fastfetch
fi
BASHPRO
sudo chmod 0755 "${BUILD_DIR}/etc/profile.d/raytolfas-motd.sh"

sudo mkdir -p "${BUILD_DIR}/home/admin"
sudo rm -rf "${BUILD_DIR}/home/admin/.config"
sudo cp -a "${BUILD_DIR}/etc/skel/.config" "${BUILD_DIR}/home/admin/"
sudo chroot "${BUILD_DIR}" /bin/bash -c "
    if ! id admin >/dev/null 2>&1; then
        useradd -m -s /bin/bash -G sudo,video,audio,input,render admin 2>/dev/null || true
        echo 'admin:admin' | chpasswd 2>/dev/null || true
    fi
    chown -R admin:admin /home/admin 2>/dev/null || chown -R 1000:1000 /home/admin 2>/dev/null || true
"

touch "${REPO_ROOT}/build/.plasma_rootfs_ready"

echo "[plasma-rootfs] Raytolfas OS D1 RootFS build completed successfully in ${BUILD_DIR}!"
