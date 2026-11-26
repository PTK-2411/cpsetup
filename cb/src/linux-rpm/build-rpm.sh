#!/usr/bin/env bash
set -euo pipefail

# Build RPM packages (Fedora / RHEL / openSUSE): ./cb/linux64.rpm and/or ./cb/linux32.rpm
# Usage: bash cb/src/linux-rpm/build-rpm.sh [64|32|all]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../common" && pwd)"
CB_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TARGET="${1:-all}"

if ! command -v rpmbuild >/dev/null 2>&1; then
    echo "[CPSetup] Loi: Can cong cu 'rpmbuild' (cai goi 'rpm' tren Ubuntu/Debian hoac 'rpm-build' tren Fedora)." >&2
    exit 1
fi

build_one() {
    local bits="$1"
    local rpm_arch
    case "$bits" in
        64) rpm_arch="x86_64" ;;
        32) rpm_arch="i686" ;;
        *)
            echo "[CPSetup] Kien truc khong hop le: $bits" >&2
            exit 1
            ;;
    esac

    local topdir
    topdir="$(mktemp -d)"
    trap 'rm -rf "$topdir"' RETURN

    mkdir -p "$topdir"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

    local spec_file="$topdir/SPECS/cpsetup-cb.spec"
    cat > "$spec_file" << EOF
Name:           cpsetup-cb
Version:        1.0.0
Release:        1
Summary:        CPSetup Code::Blocks + C++17 environment for Competitive Programming
License:        MIT
Requires:       gcc-c++, gdb, codeblocks

%description
Standardizes Code::Blocks, g++, and gdb with C++17 (-std=c++17 -O2)
defaults for HSG9 and Chuyen Tin students on Linux (${bits}-bit RPM).

%install
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/cpsetup-cb
cp -p "$COMMON_DIR/usr/bin/cb" %{buildroot}/usr/bin/cb
cp -p "$COMMON_DIR/usr/bin/cpsetup-cb-config" %{buildroot}/usr/bin/cpsetup-cb-config
cp -p "$COMMON_DIR/usr/bin/cpsetup-cb-check" %{buildroot}/usr/bin/cpsetup-cb-check
cp -p "$COMMON_DIR/usr/share/cpsetup-cb/default.conf.template" %{buildroot}/usr/share/cpsetup-cb/default.conf.template

%post
chmod 0755 /usr/bin/cb /usr/bin/cpsetup-cb-config /usr/bin/cpsetup-cb-check
if [ -n "\${SUDO_USER:-}" ] && [ "\${SUDO_USER}" != "root" ]; then
    su - "\${SUDO_USER}" -c "/usr/bin/cpsetup-cb-config" || true
fi

%files
%attr(0755, root, root) /usr/bin/cb
%attr(0755, root, root) /usr/bin/cpsetup-cb-config
%attr(0755, root, root) /usr/bin/cpsetup-cb-check
%attr(0644, root, root) /usr/share/cpsetup-cb/default.conf.template
EOF

    rpmbuild --quiet --target "$rpm_arch" --define "_topdir $topdir" -bb "$spec_file"

    local built_rpm
    built_rpm="$(find "$topdir/RPMS" -name '*.rpm' | head -n 1)"
    if [ -z "$built_rpm" ]; then
        echo "[CPSetup] Loi: Khong tim thay file RPM sau khi build." >&2
        exit 1
    fi

    local out_rpm="$CB_DIR/linux${bits}.rpm"
    cp "$built_rpm" "$out_rpm"
    echo "[CPSetup] Da build thanh cong: $out_rpm"
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
