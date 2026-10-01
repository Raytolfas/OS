#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"

ISO_ROOT="${REPO_ROOT}/build/iso"
STAGING_DIR="${ISO_ROOT}/staging"
ISO_FILE="${ISO_ROOT}/raytolfas-os-d1.iso"
ISO_TMP="${ISO_ROOT}/raytolfas-os-d1.tmp.iso"

INITRAMFS_IMAGE="${REPO_ROOT}/build/initramfs/d1-initramfs.cpio.gz"
LIMINE_DIR="${REPO_ROOT}/build/limine"
LIMINE_CONF="${REPO_ROOT}/kernel/limine.conf"

require_tool() {
    local tool="$1" hint="$2"
    if ! command -v "${tool}" > /dev/null 2>&1; then
        echo "[iso] missing tool: ${tool}"
        echo "[iso] install with: sudo apt install -y ${hint}"
        exit 1
    fi
}

require_tool xorriso "xorriso"
require_tool curl    "curl"

resolve_kernel_image() {
    local custom="${REPO_ROOT}/build/kernel/arch/x86/boot/bzImage"
    if [[ -f "${custom}" ]]; then
        echo "[iso] using custom kernel: ${custom}" >&2
        printf '%s\n' "${custom}"
        return 0
    fi

    local sys
    sys="$(ls -1t /boot/vmlinuz-* 2>/dev/null | head -n 1 || true)"
    if [[ -n "${sys}" && -f "${sys}" ]]; then
        echo "[iso] using system kernel: ${sys}" >&2
        printf '%s\n' "${sys}"
        return 0
    fi

    echo "[iso] ERROR: no kernel found. Run build-kernel.sh first." >&2
    exit 1
}

echo "[iso] checking Limine bootloader..."
bash "${SCRIPT_DIR}/fetch-limine.sh"

PLASMA_ROOTFS="/var/lib/raytolfas/plasma-rootfs"
if [[ ! -d "${PLASMA_ROOTFS}" || ! -f "${REPO_ROOT}/build/.plasma_rootfs_ready" ]]; then
    echo "[iso] preparing KDE Plasma rootfs..."
    bash "${SCRIPT_DIR}/build-plasma-rootfs.sh"
fi
echo "[iso] using KDE Plasma rootfs at ${PLASMA_ROOTFS}"
echo "[iso] building live initramfs"
bash "${SCRIPT_DIR}/build-live-initramfs.sh"

KERNEL_IMAGE="$(resolve_kernel_image)"

mkdir -p \
    "${STAGING_DIR}/boot/limine" \
    "${STAGING_DIR}/EFI/BOOT" \
    "${STAGING_DIR}/live"

if [[ -d "${PLASMA_ROOTFS}" && -f "${REPO_ROOT}/build/.plasma_rootfs_ready" ]]; then
    if [[ -d "${REPO_ROOT}/build/kernel/modules/lib/modules" ]]; then
        echo "[iso] syncing kernel modules into plasma-rootfs..."
        sudo mkdir -p "${PLASMA_ROOTFS}/lib/modules"
        sudo cp -a "${REPO_ROOT}/build/kernel/modules/lib/modules/." "${PLASMA_ROOTFS}/lib/modules/"
    fi

    echo "[iso] packing filesystem.squashfs from plasma-rootfs..."
    sudo rm -f "${STAGING_DIR}/live/filesystem.squashfs"
    sudo mksquashfs "${PLASMA_ROOTFS}" "${STAGING_DIR}/live/filesystem.squashfs" -comp zstd -Xcompression-level 15 -b 256K -no-xattrs -noappend
fi

cp -f "${KERNEL_IMAGE}"    "${STAGING_DIR}/boot/vmlinuz"
cp -f "${INITRAMFS_IMAGE}" "${STAGING_DIR}/boot/initramfs.cpio.gz"

cp -f "${LIMINE_CONF}" "${STAGING_DIR}/boot/limine/limine.conf"

cp -f "${LIMINE_DIR}/limine-bios.sys"    "${STAGING_DIR}/boot/limine/"
cp -f "${LIMINE_DIR}/limine-bios-cd.bin" "${STAGING_DIR}/boot/limine/"

if [[ -f "${LIMINE_DIR}/limine-uefi-cd.bin" ]]; then
    cp -f "${LIMINE_DIR}/limine-uefi-cd.bin" "${STAGING_DIR}/boot/limine/"
fi
for efi in "${LIMINE_DIR}/BOOTX64.EFI" "${LIMINE_DIR}/limine-uefi.efi"; do
    if [[ -f "${efi}" ]]; then
        cp -f "${efi}" "${STAGING_DIR}/EFI/BOOT/BOOTX64.EFI"
        break
    fi
done

mkdir -p "${ISO_ROOT}"

echo "[iso] building ${ISO_TMP} (Limine / xorriso)"

XORRISO_ARGS=(
    -as mkisofs
    -b boot/limine/limine-bios-cd.bin
    -no-emul-boot
    -boot-load-size 4
    -boot-info-table
    --protective-msdos-label
    -o "${ISO_TMP}"
)

if [[ -f "${STAGING_DIR}/EFI/BOOT/BOOTX64.EFI" && \
      -f "${STAGING_DIR}/boot/limine/limine-uefi-cd.bin" ]]; then
    XORRISO_ARGS+=(
        --efi-boot boot/limine/limine-uefi-cd.bin
        -efi-boot-part
        --efi-boot-image
    )
    echo "[iso] UEFI support: enabled"
else
    echo "[iso] UEFI support: disabled (EFI files not found)"
fi

XORRISO_ARGS+=( "${STAGING_DIR}" )

xorriso "${XORRISO_ARGS[@]}"

LIMINE_TOOL="${LIMINE_DIR}/limine-tool"
if [[ ! -x "${LIMINE_TOOL}" && -f "${LIMINE_DIR}/limine.c" ]]; then
    echo "[iso] compiling Limine host tool from limine.c..."
    gcc -O2 -o "${LIMINE_TOOL}" "${LIMINE_DIR}/limine.c" 2>&1 && echo "[iso] host tool compiled OK"
fi

if [[ -x "${LIMINE_TOOL}" ]]; then
    echo "[iso] installing Limine BIOS boot sector into ISO..."
    "${LIMINE_TOOL}" bios-install "${ISO_TMP}" 2>&1
    echo "[iso] BIOS boot sector installed"
else
    echo "[iso] NOTE: limine host tool not available — BIOS HDD boot won't work, but CD/DVD boot is fine"
fi

if mv -f "${ISO_TMP}" "${ISO_FILE}" 2>/dev/null; then
    echo "[iso] ready: ${ISO_FILE}"
else
    echo "[iso] NOTE: ${ISO_FILE} is locked (VirtualBox?). New ISO saved as:"
    echo "[iso]   ${ISO_TMP}"
    echo "[iso] Close the VM and run: mv '${ISO_TMP}' '${ISO_FILE}'"
    echo "[iso] Or load ${ISO_TMP} directly in VirtualBox."
fi
