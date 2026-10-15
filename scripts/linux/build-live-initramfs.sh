#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
OUTPUT_DIR="${REPO_ROOT}/build/initramfs"
OUTPUT_FILE="${OUTPUT_DIR}/d1-initramfs.cpio.gz"
STAGE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/raytolfas-live-initrd.XXXXXX")"

cleanup() {
    rm -rf "${STAGE_DIR}"
}
trap cleanup EXIT

mkdir -p "${OUTPUT_DIR}"
mkdir -p "${STAGE_DIR}"/{bin,sbin,dev,proc,sys,run,tmp,mnt,rofs,cow,rootfs,lib/modules}

cp -L /usr/bin/busybox "${STAGE_DIR}/bin/busybox"
chmod 0755 "${STAGE_DIR}/bin/busybox"

for tool in sh mount umount mkdir switch_root ls cat sleep mknod blkid losetup grep sed awk modprobe insmod mdev cut find; do
    ln -sf busybox "${STAGE_DIR}/bin/$tool"
done

MOD_SRC=""
for cand in "/var/lib/raytolfas/plasma-rootfs/lib/modules/6.8.0-146-generic" "/var/lib/raytolfas/plasma-rootfs/lib/modules"/*; do
    if [[ -d "${cand}/kernel" ]]; then
        MOD_SRC="${cand}"
        break
    fi
done

if [[ -n "${MOD_SRC}" && -d "${MOD_SRC}" ]]; then
    for name in nls_utf8 nls_iso8859-1 isofs overlay libahci ahci nvme-core nvme-auth nvme xhci-pci-renesas xhci-pci usb-storage uas mmc_block; do
        matched="$(find "${MOD_SRC}" -name "${name}.ko*" | head -n 1 || true)"
        if [[ -n "${matched}" && -f "${matched}" ]]; then
            cp -f "${matched}" "${STAGE_DIR}/lib/modules/"
        fi
    done
    if compgen -G "${STAGE_DIR}/lib/modules/*.zst" > /dev/null; then
        zstd -d --rm "${STAGE_DIR}/lib/modules/"*.zst 2>/dev/null || true
    fi
fi

cat << 'EOF' > "${STAGE_DIR}/init"
#!/bin/sh
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

mount -t devtmpfs devtmpfs /dev
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t tmpfs -o mode=0755 tmpfs /run

echo "================================================"
echo "    Starting Raytolfas OS (KDE Plasma Live)     "
echo "================================================"

echo 1 > /proc/sys/kernel/printk 2>/dev/null || true

for mod in \
    nls_utf8.ko \
    nls_iso8859-1.ko \
    isofs.ko \
    overlay.ko \
    libahci.ko \
    ahci.ko \
    nvme-core.ko \
    nvme-auth.ko \
    nvme.ko \
    xhci-pci-renesas.ko \
    xhci-pci.ko \
    usb-storage.ko \
    uas.ko \
    mmc_block.ko
do
    if [ -f "/lib/modules/$mod" ]; then
        insmod "/lib/modules/$mod" 2>/dev/null || true
    fi
done

mdev -s 2>/dev/null || true

SQUASHFS_FOUND=""
for attempt in $(seq 1 15); do
    mdev -s 2>/dev/null || true
    for dev in /dev/sr* /dev/sd* /dev/nvme*n*p* /dev/nvme* /dev/vd* /dev/mmcblk*p*; do
        if [ -b "$dev" ]; then
            mkdir -p /mnt/live_media
            if mount -o ro "$dev" /mnt/live_media 2>/dev/null; then
                if [ -f "/mnt/live_media/live/filesystem.squashfs" ]; then
                    echo "[live-init] Found Raytolfas OS media on $dev"
                    SQUASHFS_FOUND="/mnt/live_media/live/filesystem.squashfs"
                    break 2
                elif [ -f "/mnt/live_media/boot/filesystem.squashfs" ]; then
                    echo "[live-init] Found Raytolfas OS media on $dev"
                    SQUASHFS_FOUND="/mnt/live_media/boot/filesystem.squashfs"
                    break 2
                fi
                umount /mnt/live_media 2>/dev/null || true
            fi
        fi
    done
    sleep 1
done

echo 4 > /proc/sys/kernel/printk 2>/dev/null || true

if [ -z "$SQUASHFS_FOUND" ]; then
    echo "[live-init] ERROR: Could not locate filesystem.squashfs!"
    echo "[live-init] Dropping to emergency shell..."
    exec /bin/sh
fi

mkdir -p /rofs
mount -t squashfs -o ro,loop "$SQUASHFS_FOUND" /rofs

mkdir -p /cow /rootfs
mount -t tmpfs -o size=90%,mode=0755 tmpfs /cow
mkdir -p /cow/upper /cow/work

mount -t overlay overlay -o lowerdir=/rofs,upperdir=/cow/upper,workdir=/cow/work /rootfs

mkdir -p /rootfs/run /rootfs/dev /rootfs/proc /rootfs/sys /rootfs/rofs /rootfs/cdrom
mount --bind /rofs /rootfs/rofs 2>/dev/null || true
mount --bind /mnt/live_media /rootfs/cdrom 2>/dev/null || mount --move /mnt/live_media /rootfs/cdrom 2>/dev/null || true
mount --move /run /rootfs/run
mount --move /dev /rootfs/dev
mount --move /proc /rootfs/proc
mount --move /sys /rootfs/sys

echo "[live-init] Handing over to Raytolfas OS systemd init..."
exec switch_root /rootfs /sbin/init
EOF

chmod 0755 "${STAGE_DIR}/init"

(
    cd "${STAGE_DIR}"
    find . -print0 | cpio --null -ov --format=newc | gzip -9 > "${OUTPUT_FILE}"
)

echo "[live-initrd] Generated live initramfs at ${OUTPUT_FILE}"
