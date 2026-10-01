#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
MODE="${1:-auto}"

CUSTOM_KERNEL="${REPO_ROOT}/build/kernel/arch/x86/boot/bzImage"
REPO_PREBUILT_KERNEL="${REPO_ROOT}/kernel/prebuilt/bzImage"

print_if_exists() {
    local candidate="$1"
    if [[ -f "${candidate}" ]]; then
        printf '%s\n' "${candidate}"
        return 0
    fi
    return 1
}

find_latest_boot_kernel() {
    local latest=""

    latest="$(ls -1t /boot/vmlinuz-* 2>/dev/null | head -n 1 || true)"
    if [[ -n "${latest}" && -f "${latest}" ]]; then
        printf '%s\n' "${latest}"
        return 0
    fi

    latest="$(ls -1t /boot/bzImage* 2>/dev/null | head -n 1 || true)"
    if [[ -n "${latest}" && -f "${latest}" ]]; then
        printf '%s\n' "${latest}"
        return 0
    fi

    return 1
}

resolve_prebuilt_kernel() {
    if [[ -n "${RAYTOLFAS_KERNEL_IMAGE:-}" ]]; then
        if [[ -f "${RAYTOLFAS_KERNEL_IMAGE}" ]]; then
            printf '%s\n' "${RAYTOLFAS_KERNEL_IMAGE}"
            return 0
        fi

        echo "[kernel] RAYTOLFAS_KERNEL_IMAGE does not exist: ${RAYTOLFAS_KERNEL_IMAGE}" >&2
        return 1
    fi

    print_if_exists "${REPO_PREBUILT_KERNEL}" && return 0
    print_if_exists "/mnt/c/Program Files/WSL/tools/kernel" && return 0
    print_if_exists "/mnt/c/Windows/System32/lxss/tools/kernel" && return 0
    find_latest_boot_kernel && return 0

    return 1
}

case "${MODE}" in
    auto)
        print_if_exists "${CUSTOM_KERNEL}" && exit 0
        resolve_prebuilt_kernel && exit 0
        ;;
    custom)
        print_if_exists "${CUSTOM_KERNEL}" && exit 0
        ;;
    prebuilt)
        resolve_prebuilt_kernel && exit 0
        ;;
    *)
        echo "[kernel] unknown resolve mode: ${MODE}" >&2
        exit 1
        ;;
esac

exit 1
