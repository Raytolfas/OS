#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
IMG_PATH="${REPO_ROOT}/build/images/raytolfas-os-m1.img"
ISO_PATH="${REPO_ROOT}/build/iso/raytolfas-os-d1.iso"

BOOT_DRIVE_ARGS=()
if [ -f "${IMG_PATH}" ]; then
    BOOT_DRIVE_ARGS=(-drive "file=${IMG_PATH},format=raw,if=virtio")
elif [ -f "${ISO_PATH}" ]; then
    BOOT_DRIVE_ARGS=(-cdrom "${ISO_PATH}" -boot d)
else
    echo "Neither ${IMG_PATH} nor ${ISO_PATH} found."
    exit 1
fi

QEMU_BIN="qemu-system-x86_64"
if [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    ACCEL_FLAG="-enable-kvm"
    CPU_FLAG="-cpu host"
else
    ACCEL_FLAG="-accel tcg,thread=multi"
    CPU_FLAG="-cpu max"
fi

"${QEMU_BIN}" \
    ${ACCEL_FLAG} \
    -m 4G \
    -smp 4 \
    ${CPU_FLAG} \
    "${BOOT_DRIVE_ARGS[@]}" \
    -device virtio-vga,edid=on,xres=540,yres=960 \
    -display gtk,zoom-to-fit=on \
    -device qemu-xhci \
    -device usb-tablet \
    -device usb-mouse \
    -device intel-hda \
    -device hda-duplex \
    -net nic,model=virtio \
    -net user \
    -name "Raytolfas OS M1 Phone Emulator"
