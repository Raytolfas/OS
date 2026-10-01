#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
KERNEL_DIR="${REPO_ROOT}/sources/linux"
FINAL_OUTPUT_DIR="${REPO_ROOT}/build/kernel"
CONFIG_FRAGMENT="${REPO_ROOT}/kernel/configs/d1-alpha.fragment"
SOURCE_STAGING_DIR="${TMPDIR:-/tmp}/d1-linux-src-cache"
SOURCE_MARKER="${SOURCE_STAGING_DIR}/.source-revision"
BUILD_OUTPUT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/d1-kernel.XXXXXX")"

cleanup() {
    rm -rf "${BUILD_OUTPUT_DIR}"
}
trap cleanup EXIT

if [[ ! -f "${KERNEL_DIR}/arch/x86/Makefile" ]]; then
    echo "[kernel] Linux source tree is missing or incomplete, fetching it first"
    bash "${SCRIPT_DIR}/fetch-kernel.sh"
fi

mkdir -p "${FINAL_OUTPUT_DIR}"

SOURCE_REVISION="filesystem-copy"
if git -C "${KERNEL_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    SOURCE_REVISION="$(git -C "${KERNEL_DIR}" rev-parse HEAD)"
fi

if [[ ! -d "${SOURCE_STAGING_DIR}" || ! -f "${SOURCE_MARKER}" || "$(cat "${SOURCE_MARKER}")" != "${SOURCE_REVISION}" ]]; then
    echo "[kernel] staging Linux source tree in ${SOURCE_STAGING_DIR}"
    rm -rf "${SOURCE_STAGING_DIR}"
    mkdir -p "${SOURCE_STAGING_DIR}"

    if git -C "${KERNEL_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git -C "${KERNEL_DIR}" archive --format=tar HEAD | tar -xf - -C "${SOURCE_STAGING_DIR}"
    else
        cp -a "${KERNEL_DIR}/." "${SOURCE_STAGING_DIR}/"
    fi

    printf '%s\n' "${SOURCE_REVISION}" > "${SOURCE_MARKER}"
else
    echo "[kernel] reusing staged Linux source tree in ${SOURCE_STAGING_DIR}"
fi

pushd "${SOURCE_STAGING_DIR}" >/dev/null

make O="${BUILD_OUTPUT_DIR}" x86_64_defconfig

if [[ -x "./scripts/kconfig/merge_config.sh" ]]; then
    ./scripts/kconfig/merge_config.sh -O "${BUILD_OUTPUT_DIR}" "${BUILD_OUTPUT_DIR}/.config" "${CONFIG_FRAGMENT}"
else
    cat "${CONFIG_FRAGMENT}" >> "${BUILD_OUTPUT_DIR}/.config"
fi

make O="${BUILD_OUTPUT_DIR}" olddefconfig
make O="${BUILD_OUTPUT_DIR}" -j"$(nproc)"

echo "[kernel] installing kernel modules..."
rm -rf "${FINAL_OUTPUT_DIR}/modules"
make O="${BUILD_OUTPUT_DIR}" modules_install INSTALL_MOD_PATH="${FINAL_OUTPUT_DIR}/modules"

popd >/dev/null

mkdir -p "${FINAL_OUTPUT_DIR}/arch/x86/boot"
cp -f "${BUILD_OUTPUT_DIR}/arch/x86/boot/bzImage" "${FINAL_OUTPUT_DIR}/arch/x86/boot/bzImage"
cp -f "${BUILD_OUTPUT_DIR}/.config" "${FINAL_OUTPUT_DIR}/.config"

echo "[kernel] build output ready in ${FINAL_OUTPUT_DIR}"
echo "[kernel] kernel image: ${FINAL_OUTPUT_DIR}/arch/x86/boot/bzImage"
