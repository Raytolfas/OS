#!/usr/bin/env bash
set -euo pipefail

ROOTFS="${1:-/var/lib/raytolfas/plasma-rootfs}"
CACHE_DIR="/var/cache/raytolfas-cachyos"
mkdir -p "${CACHE_DIR}"

echo "[cachyos] Querying latest linux-cachyos release..."
PKG_NAME="$(curl -fsSL https://mirror.cachyos.org/repo/x86_64/cachyos/ | grep -oE 'linux-cachyos-[0-9][^"]*\.pkg\.tar\.zst' | grep -v 'headers' | grep -v 'dbg' | grep -v '\.sig' | sort -V | tail -n 1)"

if [ -z "${PKG_NAME}" ]; then
    echo "[cachyos] ERROR: Could not resolve linux-cachyos package from mirror."
    exit 1
fi

PKG_FILE="${CACHE_DIR}/${PKG_NAME}"
if [ ! -f "${PKG_FILE}" ]; then
    echo "[cachyos] Downloading ${PKG_NAME}..."
    curl -fL "https://mirror.cachyos.org/repo/x86_64/cachyos/${PKG_NAME}" -o "${PKG_FILE}"
fi

echo "[cachyos] Extracting ${PKG_NAME} into ${ROOTFS}..."
rm -rf "${ROOTFS}/usr/lib/modules/"*-generic "${ROOTFS}/boot/"*-generic "${ROOTFS}/boot/"*.old 2>/dev/null || true
tar --use-compress-program=unzstd -xf "${PKG_FILE}" -C "${ROOTFS}" usr/lib/modules/

MODDIR="$(ls -1d "${ROOTFS}/usr/lib/modules/"*-cachyos* | sort -V | tail -n 1)"
KVER="$(basename "${MODDIR}")"
echo "[cachyos] Configuring kernel version: ${KVER}"

mkdir -p "${ROOTFS}/boot"
cp -f "${MODDIR}/vmlinuz" "${ROOTFS}/boot/vmlinuz-${KVER}"
chmod 0644 "${ROOTFS}/boot/vmlinuz-${KVER}"

if [ -f "${MODDIR}/config" ]; then
    cp -f "${MODDIR}/config" "${ROOTFS}/boot/config-${KVER}"
fi
if [ -f "${MODDIR}/System.map" ]; then
    cp -f "${MODDIR}/System.map" "${ROOTFS}/boot/System.map-${KVER}"
fi

echo "[cachyos] Decompressing kernel modules (.ko.zst -> .ko)..."
find "${MODDIR}" -name '*.ko.zst' -exec zstd -d --rm -q {} +

echo "[cachyos] Running depmod and mkinitramfs for ${KVER}..."
chroot "${ROOTFS}" depmod -a "${KVER}"
chroot "${ROOTFS}" mkinitramfs -o "/boot/initrd.img-${KVER}" "${KVER}"

ln -sf "vmlinuz-${KVER}" "${ROOTFS}/boot/vmlinuz"
ln -sf "boot/vmlinuz-${KVER}" "${ROOTFS}/vmlinuz"
ln -sf "initrd.img-${KVER}" "${ROOTFS}/boot/initrd.img"
ln -sf "boot/initrd.img-${KVER}" "${ROOTFS}/initrd.img"

echo "[cachyos] Successfully installed CachyOS kernel ${KVER}!"
ls -lh "${ROOTFS}/boot"
