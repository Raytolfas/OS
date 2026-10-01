#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
SOURCES_DIR="${REPO_ROOT}/sources"
KERNEL_DIR="${SOURCES_DIR}/linux"
KERNEL_REMOTE="${KERNEL_REMOTE:-https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git}"

mkdir -p "${SOURCES_DIR}"

is_kernel_tree_valid() {
    [[ -f "${KERNEL_DIR}/Makefile" && -f "${KERNEL_DIR}/arch/x86/Makefile" ]]
}

if [[ -d "${KERNEL_DIR}" && ! -d "${KERNEL_DIR}/.git" ]]; then
    echo "[kernel] removing incomplete Linux source directory"
    rm -rf "${KERNEL_DIR}"
fi

if [[ -d "${KERNEL_DIR}/.git" && ! is_kernel_tree_valid ]]; then
    echo "[kernel] existing Linux source tree is incomplete, recloning"
    rm -rf "${KERNEL_DIR}"
fi

if [[ -d "${KERNEL_DIR}/.git" ]]; then
    echo "[kernel] updating existing Linux source tree"
    git -C "${KERNEL_DIR}" fetch --tags --prune
    git -C "${KERNEL_DIR}" pull --ff-only
else
    echo "[kernel] cloning Linux kernel from ${KERNEL_REMOTE}"
    git clone --depth 1 "${KERNEL_REMOTE}" "${KERNEL_DIR}"
fi

echo "[kernel] source available at ${KERNEL_DIR}"
