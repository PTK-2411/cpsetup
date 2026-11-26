#!/usr/bin/env bash
set -euo pipefail

# Build Debian/Ubuntu packages: ./cb/linux64.deb and/or ./cb/linux32.deb
# Usage: bash cb/src/linux-deb/build-deb.sh [64|32|all]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../common" && pwd)"
CB_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TARGET="${1:-all}"

if ! command -v dpkg-deb >/dev/null 2>&1; then
    echo "[CPSetup] Loi: Can cong cu 'dpkg-deb' (goi dpkg) de build file .deb." >&2
    exit 1
fi

build_one() {
    local bits="$1"
    local deb_arch
    case "$bits" in
        64) deb_arch="amd64" ;;
        32) deb_arch="i386" ;;
        *)
            echo "[CPSetup] Kien truc khong hop le: $bits" >&2
            exit 1
            ;;
    esac

    local stage
    stage="$(mktemp -d)"
    trap 'rm -rf "$stage"' RETURN

    mkdir -p "$stage/DEBIAN" "$stage/usr/bin" "$stage/usr/share/cpsetup-cb"
    cp "$COMMON_DIR/usr/bin/"* "$stage/usr/bin/"
    cp "$COMMON_DIR/usr/share/cpsetup-cb/default.conf.template" "$stage/usr/share/cpsetup-cb/"

    cat > "$stage/DEBIAN/control" << EOF
Package: cpsetup-cb
Version: 1.0.0
Section: devel
Priority: optional
Architecture: $deb_arch
Maintainer: CPSetup <admin@cpsetup.is-a.dev>
Depends: g++, gdb, codeblocks, build-essential
Description: CPSetup Code::Blocks + C++17 environment for Competitive Programming
 Standardizes Code::Blocks, g++, and gdb with C++17 (-std=c++17 -O2)
 defaults for HSG9 and Chuyen Tin students on Linux (${bits}-bit Debian/Ubuntu).
EOF

    cat > "$stage/DEBIAN/postinst" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

chmod 0755 /usr/bin/cb /usr/bin/cpsetup-cb-config /usr/bin/cpsetup-cb-check

if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
    su - "${SUDO_USER}" -c "/usr/bin/cpsetup-cb-config" || true
fi
EOF

    chmod 0755 "$stage/DEBIAN" "$stage/DEBIAN/postinst"
    chmod 0644 "$stage/DEBIAN/control"
    chmod 0755 "$stage/usr/bin/cb" "$stage/usr/bin/cpsetup-cb-config" "$stage/usr/bin/cpsetup-cb-check"
    chmod 0644 "$stage/usr/share/cpsetup-cb/default.conf.template"

    local out_deb="$CB_DIR/linux${bits}.deb"
    dpkg-deb --build --root-owner-group "$stage" "$out_deb"
    echo "[CPSetup] Da build thanh cong: $out_deb"
}

case "$TARGET" in
    64|32) build_one "$TARGET" ;;
    all)
        build_one 64
        build_one 32
        ;;
    *)
        echo "Usage: $0 [64|32|all]" >&2
        exit 1
        ;;
esac
