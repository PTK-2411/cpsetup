#!/usr/bin/env bash
set -euo pipefail

# Pre-fetch official Code::Blocks + MinGW Windows installers to ./cb/win64.exe & ./cb/win32.exe
# Supports resume (-C -) and retries for unstable networks.
# Usage: bash cb/src/win/fetch-codeblocks.sh [64|32|all]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CB_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TARGET="${1:-all}"

CB_VER="20.03"
URL_WIN64="https://sourceforge.net/projects/codeblocks/files/Binaries/${CB_VER}/Windows/codeblocks-${CB_VER}mingw-setup.exe/download"
URL_WIN32="https://sourceforge.net/projects/codeblocks/files/Binaries/${CB_VER}/Windows/codeblocks-${CB_VER}mingw-32bit-setup.exe/download"

download_with_resume() {
    local url="$1"
    local out="$2"
    echo "[CPSetup] Dang tai (ho tro resume): $out"
    if command -v curl >/dev/null 2>&1; then
        curl -fSL -C - --retry 5 --retry-delay 3 --connect-timeout 20 "$url" -o "$out"
    elif command -v wget >/dev/null 2>&1; then
        wget -c --tries=5 --waitretry=3 --timeout=20 -O "$out" "$url"
    else
        echo "[CPSetup] Loi: Can 'curl' hoac 'wget'." >&2
        exit 1
    fi
    echo "[CPSetup] Da tai xong: $out"
}

case "$TARGET" in
    64) download_with_resume "$URL_WIN64" "$CB_DIR/win64.exe" ;;
    32) download_with_resume "$URL_WIN32" "$CB_DIR/win32.exe" ;;
    all)
        download_with_resume "$URL_WIN64" "$CB_DIR/win64.exe"
        download_with_resume "$URL_WIN32" "$CB_DIR/win32.exe"
        ;;
    *)
        echo "Usage: $0 [64|32|all]" >&2
        exit 1
        ;;
esac
