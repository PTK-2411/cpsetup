#!/usr/bin/env bash
set -euo pipefail

# Prepare all installers in ./cb/ so the folder can be copied directly to a USB drive.
# Usage: bash cb/src/usb/prepare-usb.sh [--with-win] [--with-offline-deb]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CB_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
WITH_WIN=0
WITH_OFFLINE_DEB=0

for arg in "$@"; do
    case "$arg" in
        --with-win) WITH_WIN=1 ;;
        --with-offline-deb) WITH_OFFLINE_DEB=1 ;;
        -h|--help)
            echo "Usage: bash cb/src/usb/prepare-usb.sh [--with-win] [--with-offline-deb]"
            exit 0
            ;;
    esac
done

echo "=== CPSetup USB Builder ==="
bash "$CB_DIR/src/linux-deb/build-deb.sh" all
bash "$CB_DIR/src/linux-targz/build-targz.sh" all

if command -v rpmbuild >/dev/null 2>&1; then
    bash "$CB_DIR/src/linux-rpm/build-rpm.sh" all
else
    echo "[WARN] Khong co 'rpmbuild', bo qua build .rpm."
fi

if [ "$WITH_OFFLINE_DEB" -eq 1 ]; then
    bash "$CB_DIR/src/usb/build-offline-deb.sh"
fi

if [ "$WITH_WIN" -eq 1 ]; then
    bash "$CB_DIR/src/win/fetch-codeblocks.sh" all
fi

echo ""
echo "[CPSetup] Danh sach file trong $CB_DIR (san sang copy vao USB):"
ls -lh "$CB_DIR"
