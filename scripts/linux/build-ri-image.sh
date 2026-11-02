#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"

IMG_DIR="${REPO_ROOT}/build/images"
FINAL_XZ="${IMG_DIR}/raytolfas-os-ri.img.xz"
IMG_FILE="/var/lib/raytolfas/raytolfas-os-ri.img"
MOUNT_DIR="/tmp/ri-target-mnt"
SOURCE_ROOTFS="${RI_ROOTFS:-/var/lib/raytolfas/plasma-rootfs}"

mkdir -p "${IMG_DIR}" "/var/lib/raytolfas"

rm -f "${IMG_FILE}" "${IMG_FILE}.xz" "${FINAL_XZ}" "${IMG_DIR}/raytolfas-os-ri-v"*.img* "${IMG_DIR}/raytolfas-os-ri.img"
truncate -s 8G "${IMG_FILE}"

parted -s "${IMG_FILE}" mklabel msdos
parted -s "${IMG_FILE}" mkpart primary fat32 4MiB 260MiB
parted -s "${IMG_FILE}" set 1 boot on
parted -s "${IMG_FILE}" set 1 lba on
parted -s "${IMG_FILE}" mkpart primary ext4 260MiB 100%

LOOP_DEV="$(losetup -fP --show "${IMG_FILE}")"

cleanup() {
    sync || true
    umount "${MOUNT_DIR}/boot/firmware" 2>/dev/null || true
    umount "${MOUNT_DIR}" 2>/dev/null || true
    losetup -d "${LOOP_DEV}" 2>/dev/null || true
    rm -rf "${MOUNT_DIR}" 2>/dev/null || true
}
trap cleanup EXIT

mkfs.vfat -F 32 -n "RI_BOOT" "${LOOP_DEV}p1"
mkfs.ext4 -F -L "ri-rootfs" "${LOOP_DEV}p2"

mkdir -p "${MOUNT_DIR}"
mount "${LOOP_DEV}p2" "${MOUNT_DIR}"
mkdir -p "${MOUNT_DIR}/boot/firmware"
mount "${LOOP_DEV}p1" "${MOUNT_DIR}/boot/firmware"

if [ -d "${SOURCE_ROOTFS}" ] && [ "${FULL_RI_RSYNC:-0}" = "1" ]; then
    rsync -aAX \
        --exclude="/tmp/*" \
        --exclude="/var/tmp/*" \
        --exclude="/proc/*" \
        --exclude="/sys/*" \
        --exclude="/dev/*" \
        --exclude="/run/*" \
        "${SOURCE_ROOTFS}/." "${MOUNT_DIR}/"
else
    mkdir -p \
        "${MOUNT_DIR}/bin" \
        "${MOUNT_DIR}/boot/firmware" \
        "${MOUNT_DIR}/dev" \
        "${MOUNT_DIR}/etc/apt/apt.conf.d" \
        "${MOUNT_DIR}/etc/binfmt.d" \
        "${MOUNT_DIR}/etc/default" \
        "${MOUNT_DIR}/etc/firefox" \
        "${MOUNT_DIR}/etc/pipewire/pipewire.conf.d" \
        "${MOUNT_DIR}/etc/sddm.conf.d" \
        "${MOUNT_DIR}/etc/security/limits.d" \
        "${MOUNT_DIR}/etc/skel/.config" \
        "${MOUNT_DIR}/etc/sysctl.d" \
        "${MOUNT_DIR}/etc/systemd/system/multi-user.target.wants" \
        "${MOUNT_DIR}/etc/udev/rules.d" \
        "${MOUNT_DIR}/etc/xdg" \
        "${MOUNT_DIR}/home/admin/.config" \
        "${MOUNT_DIR}/lib/aarch64-linux-gnu" \
        "${MOUNT_DIR}/proc" \
        "${MOUNT_DIR}/root" \
        "${MOUNT_DIR}/run" \
        "${MOUNT_DIR}/sbin" \
        "${MOUNT_DIR}/sys" \
        "${MOUNT_DIR}/tmp" \
        "${MOUNT_DIR}/usr/bin" \
        "${MOUNT_DIR}/usr/lib/aarch64-linux-gnu" \
        "${MOUNT_DIR}/usr/local/bin" \
        "${MOUNT_DIR}/usr/local/lib" \
        "${MOUNT_DIR}/usr/share/applications" \
        "${MOUNT_DIR}/usr/share/fastfetch" \
        "${MOUNT_DIR}/usr/share/icons/default" \
        "${MOUNT_DIR}/usr/share/icons/hicolor/512x512/apps" \
        "${MOUNT_DIR}/usr/share/icons/hicolor/scalable/apps" \
        "${MOUNT_DIR}/usr/share/pixmaps" \
        "${MOUNT_DIR}/usr/share/raytolfas/control-center" \
        "${MOUNT_DIR}/usr/share/raytolfas/m1-shell" \
        "${MOUNT_DIR}/usr/share/raytolfas/desktop-mode" \
        "${MOUNT_DIR}/usr/share/raytolfas/console-mode" \
        "${MOUNT_DIR}/usr/share/raytolfas/spotlight" \
        "${MOUNT_DIR}/usr/share/wayland-sessions" \
        "${MOUNT_DIR}/var/lib" \
        "${MOUNT_DIR}/var/log"
fi

chmod 1777 "${MOUNT_DIR}/tmp"

cat << 'EOF' > "${MOUNT_DIR}/etc/os-release"
NAME="Raytolfas OS"
PRETTY_NAME="Raytolfas OS RI (v26.11.0)"
ID=raytolfas
ID_LIKE="ubuntu debian"
VERSION="v26.11.0"
VERSION_ID="26.11.0"
VERSION_CODENAME="noble"
HOME_URL="https://os.raytolfas.com"
LOGO=raytolfas-logo
EOF
cp -f "${MOUNT_DIR}/etc/os-release" "${MOUNT_DIR}/usr/lib/os-release" 2>/dev/null || true
echo 'Raytolfas OS RI (v26.11.0) \n \l' > "${MOUNT_DIR}/etc/issue"
echo 'Raytolfas OS RI (v26.11.0)' > "${MOUNT_DIR}/etc/issue.net"
echo "ri-pc" > "${MOUNT_DIR}/etc/hostname"

cat << 'EOF' > "${MOUNT_DIR}/etc/hosts"
127.0.0.1 localhost
127.0.1.1 ri-pc
::1 localhost ip6-localhost ip6-loopback
EOF

cat << 'EOF' > "${MOUNT_DIR}/etc/fstab"
LABEL=ri-rootfs / ext4 defaults,noatime,errors=remount-ro 0 1
LABEL=RI_BOOT /boot/firmware vfat defaults,noatime 0 2
EOF

cat << 'EOF' > "${MOUNT_DIR}/etc/default/zramswap"
ALGO=zstd
PERCENT=100
PRIORITY=100
EOF

cat << 'EOF' > "${MOUNT_DIR}/etc/sddm.conf.d/autologin.conf"
[Autologin]
User=admin
Session=plasma
Relogin=false

[Theme]
Current=breeze
CursorTheme=Bibata-Modern-Classic
EOF

cp -f "${REPO_ROOT}/config/ri/config.txt" "${MOUNT_DIR}/boot/firmware/config.txt"
cp -f "${REPO_ROOT}/config/ri/cmdline.txt" "${MOUNT_DIR}/boot/firmware/cmdline.txt"

if [ -f "${SOURCE_ROOTFS}/boot/vmlinuz" ]; then
    cp -fL "${SOURCE_ROOTFS}/boot/vmlinuz" "${MOUNT_DIR}/boot/firmware/vmlinuz"
fi
if [ -f "${SOURCE_ROOTFS}/boot/initrd.img" ]; then
    cp -fL "${SOURCE_ROOTFS}/boot/initrd.img" "${MOUNT_DIR}/boot/firmware/initrd.img"
fi

if [ -f "${REPO_ROOT}/assets/rqio/rqio" ]; then
    cp -f "${REPO_ROOT}/assets/rqio/rqio" "${MOUNT_DIR}/usr/bin/rqio-x86_64"
    chmod 0755 "${MOUNT_DIR}/usr/bin/rqio-x86_64"
    cat << 'EOF' > "${MOUNT_DIR}/usr/bin/rqio"
#!/usr/bin/env bash
if [ "$(uname -m)" = "aarch64" ] && [ -x "/usr/bin/rqio-arm64" ]; then
    exec /usr/bin/rqio-arm64 "$@"
elif [ "$(uname -m)" = "aarch64" ] && command -v qemu-x86_64-static >/dev/null 2>&1; then
    exec qemu-x86_64-static /usr/bin/rqio-x86_64 "$@"
else
    exec /usr/bin/rqio-x86_64 "$@"
fi
EOF
    chmod 0755 "${MOUNT_DIR}/usr/bin/rqio"
fi

if [ -f "${REPO_ROOT}/assets/rqio/rqio_core.so" ]; then
    cp -f "${REPO_ROOT}/assets/rqio/rqio_core.so" "${MOUNT_DIR}/usr/lib/rqio_core.so"
    cp -f "${REPO_ROOT}/assets/rqio/rqio_core.so" "${MOUNT_DIR}/usr/local/lib/rqio_core.so"
    chmod 0755 "${MOUNT_DIR}/usr/lib/rqio_core.so" "${MOUNT_DIR}/usr/local/lib/rqio_core.so"
fi

for tool in raytolfas-control-center raytolfas-turbo raytolfas-dev raytolfas-bench raytolfas-appimage raytolfas-desktop-mode raytolfas-console-mode raytolfas-spotlight raytolfas-clean raytolfas-mobile-test raytolfas-ri-growpart btrfs-auto-snapshot starship; do
    if [ -f "${REPO_ROOT}/scripts/tools/${tool}" ]; then
        cp -f "${REPO_ROOT}/scripts/tools/${tool}" "${MOUNT_DIR}/usr/bin/${tool}"
        cp -f "${REPO_ROOT}/scripts/tools/${tool}" "${MOUNT_DIR}/usr/local/bin/${tool}"
        chmod 0755 "${MOUNT_DIR}/usr/bin/${tool}" "${MOUNT_DIR}/usr/local/bin/${tool}"
    fi
done

cp -rf "${REPO_ROOT}/apps/control-center/"* "${MOUNT_DIR}/usr/share/raytolfas/control-center/"
cp -rf "${REPO_ROOT}/apps/m1-shell/"* "${MOUNT_DIR}/usr/share/raytolfas/m1-shell/"
cp -rf "${REPO_ROOT}/apps/desktop-mode/"* "${MOUNT_DIR}/usr/share/raytolfas/desktop-mode/"
cp -rf "${REPO_ROOT}/apps/console-mode/"* "${MOUNT_DIR}/usr/share/raytolfas/console-mode/"
cp -rf "${REPO_ROOT}/apps/spotlight/"* "${MOUNT_DIR}/usr/share/raytolfas/spotlight/"
rm -rf "${MOUNT_DIR}/usr/share/raytolfas/"*/__pycache__
chmod 0755 \
    "${MOUNT_DIR}/usr/share/raytolfas/control-center/main.py" \
    "${MOUNT_DIR}/usr/share/raytolfas/m1-shell/main.py" \
    "${MOUNT_DIR}/usr/share/raytolfas/desktop-mode/main.py" \
    "${MOUNT_DIR}/usr/share/raytolfas/console-mode/main.py" \
    "${MOUNT_DIR}/usr/share/raytolfas/spotlight/main.py"

if [ -d "${REPO_ROOT}/config/servicemenus" ]; then
    mkdir -p "${MOUNT_DIR}/usr/share/kio/servicemenus"
    cp -f "${REPO_ROOT}/config/servicemenus/"*.desktop "${MOUNT_DIR}/usr/share/kio/servicemenus/"
    chmod 0755 "${MOUNT_DIR}/usr/share/kio/servicemenus/"*.desktop
fi

cp -f "${REPO_ROOT}/config/sysctl/99-raytolfas-performance.conf" "${MOUNT_DIR}/etc/sysctl.d/99-raytolfas-performance.conf"
cp -f "${REPO_ROOT}/config/udev/70-game-controllers.rules" "${MOUNT_DIR}/etc/udev/rules.d/70-game-controllers.rules"
cp -f "${REPO_ROOT}/config/starship/starship.toml" "${MOUNT_DIR}/etc/starship.toml"
cp -f "${REPO_ROOT}/config/kde/kcminputrc" "${MOUNT_DIR}/etc/xdg/kcminputrc"
cp -f "${REPO_ROOT}/config/icons/default-index.theme" "${MOUNT_DIR}/usr/share/icons/default/index.theme"
cp -f "${REPO_ROOT}/config/sessions/raytolfas-console.desktop" "${MOUNT_DIR}/usr/share/wayland-sessions/raytolfas-console.desktop"
cp -f "${REPO_ROOT}/config/applications/"*.desktop "${MOUNT_DIR}/usr/share/applications/"

if [ -f "${REPO_ROOT}/config/systemd/raytolfas-ri-growpart.service" ]; then
    cp -f "${REPO_ROOT}/config/systemd/raytolfas-ri-growpart.service" "${MOUNT_DIR}/etc/systemd/system/raytolfas-ri-growpart.service"
    ln -sf "/etc/systemd/system/raytolfas-ri-growpart.service" "${MOUNT_DIR}/etc/systemd/system/multi-user.target.wants/raytolfas-ri-growpart.service"
fi

if [ -f "${REPO_ROOT}/assets/logo.svg" ]; then
    cp -f "${REPO_ROOT}/assets/logo.svg" "${MOUNT_DIR}/usr/share/pixmaps/raytolfas-logo.svg"
    cp -f "${REPO_ROOT}/assets/logo.svg" "${MOUNT_DIR}/usr/share/icons/hicolor/scalable/apps/raytolfas-logo.svg"
fi
if [ -f "${REPO_ROOT}/assets/logo.png" ]; then
    cp -f "${REPO_ROOT}/assets/logo.png" "${MOUNT_DIR}/usr/share/pixmaps/raytolfas-logo.png"
    cp -f "${REPO_ROOT}/assets/logo.png" "${MOUNT_DIR}/usr/share/icons/hicolor/512x512/apps/raytolfas-logo.png"
fi
if [ -f "${REPO_ROOT}/assets/logo.txt" ]; then
    cp -f "${REPO_ROOT}/assets/logo.txt" "${MOUNT_DIR}/usr/share/fastfetch/raytolfas-logo.txt"
fi

sync
umount "${MOUNT_DIR}/boot/firmware" 2>/dev/null || true
umount "${MOUNT_DIR}" 2>/dev/null || true
losetup -d "${LOOP_DEV}" 2>/dev/null || true
rm -rf "${MOUNT_DIR}" 2>/dev/null || true
trap - EXIT

xz -T0 -2 -f "${IMG_FILE}"
mv -f "${IMG_FILE}.xz" "${FINAL_XZ}"
(
    cd "${IMG_DIR}"
    sha256sum "raytolfas-os-ri.img.xz" > "raytolfas-os-ri.img.xz.sha256"
    md5sum "raytolfas-os-ri.img.xz" > "raytolfas-os-ri.img.xz.md5"
)

echo "[build-ri] Built Raspberry Pi image: ${FINAL_XZ}"
