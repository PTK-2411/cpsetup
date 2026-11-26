#!/usr/bin/env bash
set -euo pipefail

# Build an offline Ubuntu/Debian USB bundle: ./cb/linux64-offline.tar.gz
# Contains ./cb/linux64.deb + all required .deb dependencies (codeblocks, g++, gdb, build-essential)
# Usage: bash cb/src/usb/build-offline-deb.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CB_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUT_TGZ="$CB_DIR/linux64-offline.tar.gz"

if ! command -v apt-get >/dev/null 2>&1 || ! command -v apt-cache >/dev/null 2>&1; then
    echo "[CPSetup] Loi: Can Ubuntu/Debian (apt-get, apt-cache) de tai cache goi offline." >&2
    exit 1
fi

if [ ! -f "$CB_DIR/linux64.deb" ]; then
    bash "$CB_DIR/src/linux-deb/build-deb.sh" 64
fi

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

BUNDLE_DIR="$STAGE/cpsetup-cb-linux64-offline"
DEBS_DIR="$BUNDLE_DIR/debs"
mkdir -p "$DEBS_DIR"

cp "$CB_DIR/linux64.deb" "$BUNDLE_DIR/linux64.deb"

echo "[CPSetup] Dang thu thap danh sach goi phu thuoc (g++, gdb, codeblocks, build-essential)..."
PKGS="$(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances \
    g++ gdb codeblocks build-essential | grep -E '^[a-z0-9][a-z0-9+.-]*$' | sort -u)"

echo "[CPSetup] Dang tai $(echo "$PKGS" | wc -l) goi .deb ve thu muc offline (song song 8 luong)..."
(
    cd "$DEBS_DIR"
    echo "$PKGS" | xargs -P 8 -n 10 sh -c 'apt-get download "$@" >/dev/null 2>&1 || true' _
)

DEB_COUNT="$(find "$DEBS_DIR" -maxdepth 1 -name '*.deb' | wc -l)"
if [ "$DEB_COUNT" -eq 0 ]; then
    echo "[CPSetup] Loi: Khong tai duoc goi .deb nao." >&2
    exit 1
fi

cat > "$BUNDLE_DIR/install-offline.sh" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
run_privileged() {
    if [ "$(id -u)" -eq 0 ]; then "$@"
    elif command -v sudo >/dev/null 2>&1; then sudo "$@"
    else echo "[CPSetup] Can quyen root hoac sudo." >&2; exit 1
    fi
}

echo "[CPSetup] Dang cai dat offline tu USB (khong can mang)..."
run_privileged dpkg -i --force-depends "$SCRIPT_DIR/debs/"*.deb || true
run_privileged dpkg -i "$SCRIPT_DIR/linux64.deb" || true
run_privileged apt-get install -f -y --no-download >/dev/null 2>&1 || true

if command -v cpsetup-cb-config >/dev/null 2>&1; then
    cpsetup-cb-config
fi
echo "[CPSetup] Cai dat offline hoan tat! Go 'cb' de mo Code::Blocks."
EOF
chmod 0755 "$BUNDLE_DIR/install-offline.sh"

tar -czf "$OUT_TGZ" -C "$STAGE" "cpsetup-cb-linux64-offline"
echo "[CPSetup] Da tao goi USB offline ($DEB_COUNT file .deb): $OUT_TGZ"
