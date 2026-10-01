#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
ISO_IMAGE="${REPO_ROOT}/build/iso/raytolfas-d1-alpha.iso"
INITRAMFS_IMAGE="${REPO_ROOT}/build/initramfs/d1-alpha-initramfs.cpio.gz"
KERNEL_MODE="${RAYTOLFAS_KERNEL_MODE:-auto}"
QEMU_UI="${RAYTOLFAS_QEMU_UI:-gui}"

if [[ -z "${DISPLAY:-}" && -S /tmp/.X11-unix/X0 ]]; then
    export DISPLAY=":0"
fi
if [[ -z "${WAYLAND_DISPLAY:-}" && -S /mnt/wslg/runtime-dir/wayland-0 ]]; then
    export WAYLAND_DISPLAY="wayland-0"
    export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/mnt/wslg/runtime-dir}"
fi
if [[ -z "${XDG_RUNTIME_DIR:-}" && -d "/mnt/wslg/runtime-dir" ]]; then
    export XDG_RUNTIME_DIR="/mnt/wslg/runtime-dir"
fi

ACCEL_ARGS=()
if [[ -w /dev/kvm || -r /dev/kvm ]]; then
    ACCEL_ARGS=(-accel kvm -accel tcg -cpu host)
else
    ACCEL_ARGS=(-accel tcg)
fi

if [[ "${QEMU_UI}" == "gui" ]]; then
    QEMU_UI_ARGS=(
        -vga std
        -usb
        -device usb-tablet
        -display gtk,gl=off,show-cursor=on
    )
else
    QEMU_UI_ARGS=(
        -display none
    )
fi

if [[ -f "${ISO_IMAGE}" && "${RAYTOLFAS_DIRECT_KERNEL:-0}" != "1" ]]; then
    echo "[qemu] Booting Raytolfas OS ISO: ${ISO_IMAGE}"
    QEMU_ARGS=(
        -machine q35
        "${ACCEL_ARGS[@]}"
        -m 4096
        -smp 4
        -serial mon:stdio
        -cdrom "${ISO_IMAGE}"
        -boot d
        "${QEMU_UI_ARGS[@]}"
    )
    exec qemu-system-x86_64 "${QEMU_ARGS[@]}"
fi

if [[ ! -f "${INITRAMFS_IMAGE}" ]]; then
    echo "[qemu] initramfs missing, building it first"
    bash "${SCRIPT_DIR}/build-initramfs.sh"
fi

resolve_kernel_image() {
    local resolved=""
    if resolved="$(bash "${SCRIPT_DIR}/resolve-kernel-image.sh" "${KERNEL_MODE}")"; then
        printf '%s\n' "${resolved}"
        return 0
    fi
    echo "[qemu] kernel image missing, building project kernel"
    bash "${SCRIPT_DIR}/build-kernel.sh"
    bash "${SCRIPT_DIR}/resolve-kernel-image.sh" custom
}

KERNEL_IMAGE="$(resolve_kernel_image)"
echo "[qemu] using direct kernel image: ${KERNEL_IMAGE}"
echo "[qemu] using initramfs: ${INITRAMFS_IMAGE}"

QEMU_APPEND="console=tty0 console=ttyS0,115200n8 rdinit=/init loglevel=4"
QEMU_ARGS=(
    -machine q35
    "${ACCEL_ARGS[@]}"
    -m 4096
    -smp 4
    -serial mon:stdio
    -kernel "${KERNEL_IMAGE}"
    -initrd "${INITRAMFS_IMAGE}"
    -append "${QEMU_APPEND}"
    "${QEMU_UI_ARGS[@]}"
)

exec qemu-system-x86_64 "${QEMU_ARGS[@]}"
