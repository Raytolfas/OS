#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"

IMG_DIR="${REPO_ROOT}/build/images"
IMG_FILE="${IMG_DIR}/raytolfas-os-m1.img"
PLASMA_ROOTFS="/var/lib/raytolfas/plasma-rootfs"
MOUNT_DIR="/tmp/m1-target-mnt"
LIMINE_DIR="${REPO_ROOT}/build/limine"

mkdir -p "${IMG_DIR}"

if [ ! -d "${PLASMA_ROOTFS}" ]; then
    echo "Rootfs not found at ${PLASMA_ROOTFS}"
    exit 1
fi

truncate -s 14G "${IMG_FILE}"

parted -s "${IMG_FILE}" mklabel gpt
parted -s "${IMG_FILE}" mkpart "bios_boot" 1MiB 4MiB
parted -s "${IMG_FILE}" set 1 bios_grub on
parted -s "${IMG_FILE}" mkpart "ESP" fat32 4MiB 264MiB
parted -s "${IMG_FILE}" set 2 esp on
parted -s "${IMG_FILE}" mkpart "RaytolfasM1" ext4 264MiB 100%

LOOP_DEV=$(sudo losetup -fP --show "${IMG_FILE}")

cleanup() {
    sync || true
    sudo umount "${MOUNT_DIR}/boot/efi" 2>/dev/null || true
    sudo umount "${MOUNT_DIR}" 2>/dev/null || true
    sudo losetup -d "${LOOP_DEV}" 2>/dev/null || true
    rm -rf "${MOUNT_DIR}" 2>/dev/null || true
}
trap cleanup EXIT

sudo mkfs.vfat -F 32 -n "M1_BOOT" "${LOOP_DEV}p2"
sudo mkfs.ext4 -F -L "m1-rootfs" "${LOOP_DEV}p3"

sudo mkdir -p "${MOUNT_DIR}"
sudo mount "${LOOP_DEV}p3" "${MOUNT_DIR}"
sudo mkdir -p "${MOUNT_DIR}/boot/efi"
sudo mount "${LOOP_DEV}p2" "${MOUNT_DIR}/boot/efi"

sudo rsync -aAX \
    --exclude="/tmp/*" \
    --exclude="/var/tmp/*" \
    --exclude="/proc/*" \
    --exclude="/sys/*" \
    --exclude="/dev/*" \
    --exclude="/run/*" \
    "${PLASMA_ROOTFS}/." "${MOUNT_DIR}/"

sudo mkdir -p "${MOUNT_DIR}/proc" "${MOUNT_DIR}/sys" "${MOUNT_DIR}/dev" "${MOUNT_DIR}/run" "${MOUNT_DIR}/tmp"
sudo chmod 1777 "${MOUNT_DIR}/tmp"

cat << 'EOF' | sudo tee "${MOUNT_DIR}/etc/os-release" > /dev/null
NAME="Raytolfas OS"
PRETTY_NAME="Raytolfas OS M1 (v26.10.2)"
ID=raytolfas
ID_LIKE="ubuntu debian"
VERSION="v26.10.2"
VERSION_ID="26.10.2"
VERSION_CODENAME="noble"
HOME_URL="https://os.raytolfas.cc"
EOF

sudo cp -f "${MOUNT_DIR}/etc/os-release" "${MOUNT_DIR}/usr/lib/os-release" 2>/dev/null || true
echo 'Raytolfas OS M1 (v26.10.2)' | sudo tee "${MOUNT_DIR}/etc/issue" "${MOUNT_DIR}/etc/issue.net" > /dev/null
echo "m1-phone" | sudo tee "${MOUNT_DIR}/etc/hostname" > /dev/null
sudo sed -i "s/d1-pc/m1-phone/g; s/raytolfas-pc/m1-phone/g" "${MOUNT_DIR}/etc/hosts" 2>/dev/null || true

cat << 'EOF' | sudo tee "${MOUNT_DIR}/etc/fstab" > /dev/null
LABEL=m1-rootfs / ext4 defaults,noatime,errors=remount-ro 0 1
LABEL=M1_BOOT /boot/efi vfat umask=0077 0 1
EOF

sudo mkdir -p "${MOUNT_DIR}/etc/sddm.conf.d"
cat << 'EOF' | sudo tee "${MOUNT_DIR}/etc/sddm.conf.d/autologin.conf" > /dev/null
[Autologin]
User=admin
Session=plasma-mobile
Relogin=false

[Theme]
Current=Fluent
CursorTheme=breeze_cursors
EOF

cat << 'EOF' | sudo tee "${MOUNT_DIR}/etc/environment" > /dev/null
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
QT_QPA_PLATFORM="wayland;xcb"
QT_QUICK_CONTROLS_MOBILE=true
PLASMA_PLATFORM=phone:handset
EOF

sudo mkdir -p "${MOUNT_DIR}/boot/efi/EFI/BOOT"
sudo mkdir -p "${MOUNT_DIR}/boot/efi/boot"
sudo cp -f "${REPO_ROOT}/build/limine/BOOTX64.EFI" "${MOUNT_DIR}/boot/efi/EFI/BOOT/BOOTX64.EFI"
sudo cp -f "${REPO_ROOT}/build/limine/limine-bios.sys" "${MOUNT_DIR}/boot/efi/limine-bios.sys"
sudo cp -f "${REPO_ROOT}/build/limine/limine-bios.sys" "${MOUNT_DIR}/boot/limine-bios.sys"

if [ -f "${MOUNT_DIR}/boot/vmlinuz" ]; then
    sudo cp -fL "${MOUNT_DIR}/boot/vmlinuz" "${MOUNT_DIR}/boot/efi/boot/vmlinuz"
fi
if [ -f "${MOUNT_DIR}/boot/initrd.img" ]; then
    sudo cp -fL "${MOUNT_DIR}/boot/initrd.img" "${MOUNT_DIR}/boot/efi/boot/initrd.img"
fi

cat << 'EOF' | sudo tee "${MOUNT_DIR}/boot/efi/limine.conf" "${MOUNT_DIR}/boot/efi/EFI/BOOT/limine.conf" "${MOUNT_DIR}/boot/limine.conf" > /dev/null
timeout: 2
serial: no
term_background: 000000

/Raytolfas OS M1
    protocol: linux
    path: boot():/boot/vmlinuz
    module_path: boot():/boot/initrd.img
    cmdline: root=LABEL=m1-rootfs rw quiet splash video=Virtual-1:540x960@60 console=tty0
EOF

if [ -f "${MOUNT_DIR}/usr/share/icons/hicolor/scalable/apps/raytolfas-logo.svg" ]; then
    gzip -c "${MOUNT_DIR}/usr/share/icons/hicolor/scalable/apps/raytolfas-logo.svg" | sudo tee "${MOUNT_DIR}/usr/share/plasma/desktoptheme/Fluent-round-dark/icons/start.svgz" > /dev/null
    sudo cp -f "${MOUNT_DIR}/usr/share/icons/hicolor/scalable/apps/raytolfas-logo.svg" "${MOUNT_DIR}/usr/share/icons/hicolor/scalable/apps/start-here-kde.svg" 2>/dev/null || true
    sudo cp -f "${MOUNT_DIR}/usr/share/icons/hicolor/scalable/apps/raytolfas-logo.svg" "${MOUNT_DIR}/usr/share/icons/breeze/apps/48/start-here-kde.svg" 2>/dev/null || true
    sudo cp -f "${MOUNT_DIR}/usr/share/icons/hicolor/scalable/apps/raytolfas-logo.svg" "${MOUNT_DIR}/usr/share/icons/breeze-dark/apps/48/start-here-kde.svg" 2>/dev/null || true
fi

sync
sudo umount "${MOUNT_DIR}/boot/efi" 2>/dev/null || true
sudo umount "${MOUNT_DIR}" 2>/dev/null || true
sudo losetup -d "${LOOP_DEV}" 2>/dev/null || true
rm -rf "${MOUNT_DIR}" 2>/dev/null || true
trap - EXIT

if [ -x "${REPO_ROOT}/build/limine/limine-tool" ]; then
    sudo "${REPO_ROOT}/build/limine/limine-tool" bios-install --force "${IMG_FILE}"
fi

echo "[build-m1] Successfully built image at ${IMG_FILE}"
