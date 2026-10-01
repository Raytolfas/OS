#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
LIMINE_DIR="${REPO_ROOT}/build/limine"
MARKER="${LIMINE_DIR}/.version"
LIMINE_REPO="limine-bootloader/limine"

if [[ -f "${MARKER}" && -f "${LIMINE_DIR}/limine-bios-cd.bin" ]]; then
    echo "[limine] already fetched ($(cat "${MARKER}"))"
    exit 0
fi

echo "[limine] searching GitHub releases for binary tarball..."

ALL_RELEASES="$(curl -fsSL "https://api.github.com/repos/${LIMINE_REPO}/releases?per_page=10")"

TARBALL_URL="$(echo "${ALL_RELEASES}" \
    | grep '"browser_download_url"' \
    | grep 'binary.*\.tar\.xz\|\.tar\.xz.*binary' \
    | head -n 1 \
    | sed 's/.*"browser_download_url": *"\([^"]*\)".*/\1/')"

TAG="$(echo "${ALL_RELEASES}" \
    | grep '"tag_name"' \
    | head -n 1 \
    | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')"

if [[ -z "${TARBALL_URL}" ]]; then
    echo "[limine] WARNING: auto-detect failed, using known Limine 8.x URL"
    TARBALL_URL="https://github.com/limine-bootloader/limine/releases/download/v8.9.3/limine-v8.9.3-binary.tar.xz"
    TAG="v8.9.3"
fi

echo "[limine] release tag : ${TAG}"
echo "[limine] tarball URL : ${TARBALL_URL}"

rm -rf "${LIMINE_DIR}"
mkdir -p "${LIMINE_DIR}"

TMP_TAR="$(mktemp /tmp/limine-XXXXXX.tar.xz)"
trap 'rm -f "${TMP_TAR}"' EXIT

curl -fsSL -o "${TMP_TAR}" "${TARBALL_URL}"

echo "[limine] extracting..."
tar -xf "${TMP_TAR}" --strip-components=1 -C "${LIMINE_DIR}"

echo "[limine] extracted (top-level):"
find "${LIMINE_DIR}" -maxdepth 1 | sort

if [[ ! -f "${LIMINE_DIR}/limine-bios-cd.bin" ]]; then
    echo "[limine] limine-bios-cd.bin missing — trying Limine v7 fallback"
    FALLBACK="https://github.com/limine-bootloader/limine/releases/download/v7.13.3/limine-v7.13.3-binary.tar.xz"
    TAG="v7.13.3"
    rm -rf "${LIMINE_DIR}" && mkdir -p "${LIMINE_DIR}"
    curl -fsSL -o "${TMP_TAR}" "${FALLBACK}"
    tar -xf "${TMP_TAR}" --strip-components=1 -C "${LIMINE_DIR}"
fi

if [[ ! -f "${LIMINE_DIR}/limine-bios-cd.bin" ]]; then
    echo "[limine] FATAL: limine-bios-cd.bin still not found after fallback."
    echo "[limine] Files found:"
    find "${LIMINE_DIR}" -maxdepth 2 | sort
    exit 1
fi

echo "${TAG}" > "${MARKER}"
echo "[limine] SUCCESS — binary files:"
ls -lh "${LIMINE_DIR}/"*.bin "${LIMINE_DIR}/"*.sys 2>/dev/null || true
[[ -f "${LIMINE_DIR}/limine" ]] && echo "[limine] host tool: present" || echo "[limine] host tool: not found (optional)"
