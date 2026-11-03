#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"

IMG_DIR="${REPO_ROOT}/build/images"
FINAL_XZ="${IMG_DIR}/raytolfas-os-m1.img.xz"
IMG_FILE="/var/lib/raytolfas/raytolfas-os-m1.tmp.img"
PLASMA_ROOTFS="/var/lib/raytolfas/plasma-rootfs"
MOUNT_DIR="/tmp/m1-target-mnt"
LIMINE_DIR="${REPO_ROOT}/build/limine"

mkdir -p "${IMG_DIR}" "/var/lib/raytolfas"

if [ ! -d "${PLASMA_ROOTFS}" ]; then
    echo "Rootfs not found at ${PLASMA_ROOTFS}"
    exit 1
fi

rm -f "${IMG_FILE}" "${IMG_FILE}.xz" "${FINAL_XZ}" "${IMG_DIR}/raytolfas-os-m1.img" "${IMG_DIR}/raytolfas-os-m1-v"*.img*
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
PRETTY_NAME="Raytolfas OS M1 (v26.11.1)"
ID=raytolfas
ID_LIKE="ubuntu debian"
VERSION="v26.11.1"
VERSION_ID="26.11.1"
VERSION_CODENAME="noble"
HOME_URL="https://os.raytolfas.com"
LOGO=raytolfas-logo
EOF

sudo cp -f "${MOUNT_DIR}/etc/os-release" "${MOUNT_DIR}/usr/lib/os-release" 2>/dev/null || true
echo 'Raytolfas OS M1 (v26.11.1)' | sudo tee "${MOUNT_DIR}/etc/issue" "${MOUNT_DIR}/etc/issue.net" > /dev/null
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
Current=breeze
CursorTheme=Bibata-Modern-Classic
EOF

cat << 'EOF' | sudo tee "${MOUNT_DIR}/etc/environment" > /dev/null
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
QT_QPA_PLATFORM="wayland;xcb"
QT_QUICK_CONTROLS_MOBILE=true
PLASMA_PLATFORM=phone:handset
LANG="en_US.UTF-8"
LC_ALL="en_US.UTF-8"
LANGUAGE="en_US:en"
EOF

sudo mkdir -p "${MOUNT_DIR}/boot/efi/EFI/BOOT"
sudo mkdir -p "${MOUNT_DIR}/boot/efi/boot"
sudo cp -f "${REPO_ROOT}/build/limine/BOOTAA64.EFI" "${MOUNT_DIR}/boot/efi/EFI/BOOT/BOOTAA64.EFI"
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

/Raytolfas OS M1 (Native Phone Display)
    protocol: linux
    path: boot():/boot/vmlinuz
    module_path: boot():/boot/initrd.img
    cmdline: root=LABEL=m1-rootfs rw quiet splash console=tty0

/Raytolfas OS M1 (Phone 720x1440)
    protocol: linux
    path: boot():/boot/vmlinuz
    module_path: boot():/boot/initrd.img
    cmdline: root=LABEL=m1-rootfs rw quiet splash video=720x1440@60 console=tty0

/Raytolfas OS M1 (Phone 1080x1920)
    protocol: linux
    path: boot():/boot/vmlinuz
    module_path: boot():/boot/initrd.img
    cmdline: root=LABEL=m1-rootfs rw quiet splash video=1080x1920@60 console=tty0

/Raytolfas OS M1 (Emulator 540x960)
    protocol: linux
    path: boot():/boot/vmlinuz
    module_path: boot():/boot/initrd.img
    cmdline: root=LABEL=m1-rootfs rw quiet splash video=Virtual-1:540x960@60 console=tty0
EOF

if [ -f "${MOUNT_DIR}/usr/share/icons/hicolor/scalable/apps/raytolfas-logo.svg" ]; then
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

echo "[build-m1] Compressing image with xz..."
xz -T0 -2 -f "${IMG_FILE}"
mv -f "${IMG_FILE}.xz" "${FINAL_XZ}"
(
    cd "${IMG_DIR}"
    sha256sum "raytolfas-os-m1.img.xz" > "raytolfas-os-m1.img.xz.sha256"
    md5sum "raytolfas-os-m1.img.xz" > "raytolfas-os-m1.img.xz.md5"
)
rm -f "${IMG_DIR}/raytolfas-os-m1.img"

echo "[build-m1] Successfully built image at ${FINAL_XZ}"
